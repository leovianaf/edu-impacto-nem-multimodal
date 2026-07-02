from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterator

import duckdb
from dotenv import load_dotenv
from neo4j import GraphDatabase
from pymongo import MongoClient, ReplaceOne

PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / '.env')

DUCKDB_PATH = PROJECT_ROOT / 'edu_impacto_nem_multimodal.duckdb'
SERVING_TABLES = [
    'srv_municipio_ano_painel_educacional',
    'srv_municipio_ano_nem',
    'srv_municipio_ano_tecnico',
    'srv_escola_ano_em',
    'srv_escola_ano_tecnico',
    'srv_escola_ano_em_tecnico',
]

REQUIRED_ENV_VARS = (
    'MONGO_URI',
    'MONGO_DB',
    'NEO4J_URI',
    'NEO4J_USER',
    'NEO4J_PASSWORD',
)
missing_env_vars = [name for name in REQUIRED_ENV_VARS if not os.getenv(name)]
if missing_env_vars:
    raise RuntimeError(
        'Variáveis de ambiente obrigatórias ausentes ou vazias: '
        + ', '.join(missing_env_vars)
    )

MONGO_URI = os.environ['MONGO_URI']
MONGO_DB = os.environ['MONGO_DB']
NEO4J_URI = os.environ['NEO4J_URI']
NEO4J_USER = os.environ['NEO4J_USER']
NEO4J_PASSWORD = os.environ['NEO4J_PASSWORD']
BATCH_SIZE = int(os.getenv('NOSQL_BATCH_SIZE', '1000'))

if BATCH_SIZE <= 0:
    raise ValueError('NOSQL_BATCH_SIZE deve ser maior que zero')


def iter_query_batches(
    con: duckdb.DuckDBPyConnection,
    query: str,
    batch_size: int = BATCH_SIZE,
) -> Iterator[list[dict]]:
    """Lê o resultado em lotes sem materializar a tabela inteira em memória."""
    cursor = con.execute(query)
    columns = [column[0] for column in cursor.description]
    while rows := cursor.fetchmany(batch_size):
        yield [dict(zip(columns, row)) for row in rows]


def run_neo4j_batches(
    session,
    query: str,
    records: Iterator[list[dict]],
    label: str,
) -> None:
    total = 0
    for batch_number, batch in enumerate(records, start=1):
        session.run(query, rows=batch).consume()
        total += len(batch)
        print(f'Neo4j: {label} - lote {batch_number} ({len(batch)} registros)', flush=True)
    print(f'Neo4j: {label} - total {total} registros', flush=True)


def export_mongo(con: duckdb.DuckDBPyConnection) -> None:
    keys_by_table = {
        'srv_municipio_ano_painel_educacional': ['ano', 'id_municipio'],
        'srv_municipio_ano_nem': ['ano', 'id_municipio'],
        'srv_municipio_ano_tecnico': ['ano', 'id_municipio'],
        'srv_escola_ano_em': ['ano', 'id_municipio', 'id_escola'],
        'srv_escola_ano_tecnico': ['ano', 'id_municipio', 'id_escola'],
        'srv_escola_ano_em_tecnico': ['ano', 'id_municipio', 'id_escola'],
    }

    with MongoClient(MONGO_URI) as client:
        db = client[MONGO_DB]
        for table_name in SERVING_TABLES:
            collection = db[table_name]
            collection.create_index(
                [(key, 1) for key in keys_by_table[table_name]],
                unique=True,
                name='serving_natural_key',
            )
            total = 0
            for batch_number, rows in enumerate(
                iter_query_batches(con, f'select * from {table_name}'),
                start=1,
            ):
                ops = [
                    ReplaceOne(
                        {key: row[key] for key in keys_by_table[table_name]},
                        row,
                        upsert=True,
                    )
                    for row in rows
                ]
                collection.bulk_write(ops, ordered=False)
                total += len(rows)
                print(
                    f'MongoDB: {table_name} - lote {batch_number} '
                    f'({len(rows)} registros)',
                    flush=True,
                )
            print(f'MongoDB: {table_name} - total {total} registros', flush=True)


def export_neo4j(con: duckdb.DuckDBPyConnection) -> None:
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    with driver.session() as session:
        session.run('CREATE CONSTRAINT municipio_id IF NOT EXISTS FOR (m:Municipio) REQUIRE m.id_municipio IS UNIQUE').consume()
        session.run('CREATE CONSTRAINT escola_id IF NOT EXISTS FOR (e:Escola) REQUIRE e.id_escola IS UNIQUE').consume()
        session.run('CREATE CONSTRAINT ano_id IF NOT EXISTS FOR (a:Ano) REQUIRE a.ano IS UNIQUE').consume()

        run_neo4j_batches(
            session,
            """
            UNWIND $rows AS row
            MERGE (m:Municipio {id_municipio: row.id_municipio})
            SET m.nome_municipio = row.nome_municipio,
                m.id_uf = row.id_uf,
                m.sigla_uf = row.sigla_uf,
                m.nome_uf = row.nome_uf,
                m.nome_regiao = row.nome_regiao,
                m.capital_uf = row.capital_uf,
                m.amazonia_legal = row.amazonia_legal
            """,
            iter_query_batches(
                con,
                """
                select distinct id_municipio, nome_municipio, id_uf, sigla_uf,
                                nome_uf, nome_regiao, capital_uf, amazonia_legal
                from srv_municipio_ano_painel_educacional
                """,
            ),
            'municípios',
        )
        run_neo4j_batches(
            session,
            'UNWIND $rows AS row MERGE (a:Ano {ano: row.ano})',
            iter_query_batches(
                con,
                'select distinct ano from srv_municipio_ano_painel_educacional',
            ),
            'anos',
        )
        run_neo4j_batches(
            session,
            """
            UNWIND $rows AS row
            MATCH (m:Municipio {id_municipio: row.id_municipio})
            MATCH (a:Ano {ano: row.ano})
            MERGE (m)-[r:PAINEL_MUNICIPAL]->(a)
            SET r.periodo_nem = row.periodo_nem,
                r.tem_saeb_no_ano_flag = row.tem_saeb_no_ano_flag,
                r.in_ano_edicao_saeb = row.in_ano_edicao_saeb,
                r.qt_escolas_em = row.qt_escolas_em,
                r.qt_mat_med = row.qt_mat_med,
                r.qt_mat_prof_tec = row.qt_mat_prof_tec,
                r.prop_mat_em_integral = row.prop_mat_em_integral,
                r.prop_escolas_prof_tec = row.prop_escolas_prof_tec,
                r.pib_per_capita = row.pib_per_capita,
                r.taxa_alfabetizacao = row.taxa_alfabetizacao,
                r.prop_mat_em_tecnico_profissional = row.prop_mat_em_tecnico_profissional,
                r.prop_escolas_em_integral = row.prop_escolas_em_integral,
                r.prop_escolas_itinerario_tecn_prof = row.prop_escolas_itinerario_tecn_prof,
                r.prop_escolas_com_curso_tecnico = row.prop_escolas_com_curso_tecnico,
                r.media_12_lp = row.media_12_lp,
                r.media_12_mt = row.media_12_mt,
                r.media_12_lp_mt = row.media_12_lp_mt,
                r.delta_media_12_lp = row.delta_media_12_lp,
                r.delta_media_12_mt = row.delta_media_12_mt,
                r.delta_media_12_lp_mt = row.delta_media_12_lp_mt
            """,
            iter_query_batches(
                con,
                """
                select ano, id_municipio, periodo_nem, tem_saeb_no_ano_flag,
                       in_ano_edicao_saeb, qt_escolas_em, qt_mat_med,
                       qt_mat_prof_tec, prop_mat_em_integral,
                       prop_escolas_prof_tec, pib_per_capita, taxa_alfabetizacao,
                       prop_mat_em_tecnico_profissional,
                       prop_escolas_em_integral,
                       prop_escolas_itinerario_tecn_prof,
                       prop_escolas_com_curso_tecnico,
                       media_12_lp, media_12_mt, media_12_lp_mt,
                       delta_media_12_lp, delta_media_12_mt, delta_media_12_lp_mt
                from srv_municipio_ano_painel_educacional
                """,
            ),
            'painéis municipais',
        )
        run_neo4j_batches(
            session,
            """
            UNWIND $rows AS row
            MERGE (e:Escola {id_escola: row.id_escola})
            SET e.no_entidade = row.no_entidade,
                e.id_municipio = row.id_municipio,
                e.nome_municipio = row.nome_municipio,
                e.sigla_uf = row.sigla_uf
            WITH e, row
            MATCH (m:Municipio {id_municipio: row.id_municipio})
            MERGE (e)-[:PERTENCE_A]->(m)
            """,
            iter_query_batches(
                con,
                """
                select distinct id_escola, no_entidade, id_municipio,
                                nome_municipio, sigla_uf
                from srv_escola_ano_em_tecnico
                """,
            ),
            'escolas e municípios',
        )
        run_neo4j_batches(
            session,
            """
            UNWIND $rows AS row
            MATCH (e:Escola {id_escola: row.id_escola})
            MATCH (a:Ano {ano: row.ano})
            MERGE (e)-[r:OFERTA_EM_TECNICO]->(a)
            SET r.tem_em_e_tecnico_no_mesmo_ano = row.tem_em_e_tecnico_no_mesmo_ano,
                r.tem_em_e_tecnico_no_nem = row.tem_em_e_tecnico_no_nem,
                r.id_municipio = row.id_municipio,
                r.in_med_padronizado = row.in_med_padronizado,
                r.in_prof_tec = row.in_prof_tec,
                r.prop_mat_em_integral_escola = row.prop_mat_em_integral_escola,
                r.qt_mat_med = row.qt_mat_med_compat,
                r.in_internet_aprendizagem = row.in_internet_aprendizagem,
                r.in_biblioteca = row.in_biblioteca,
                r.in_laboratorio_ciencias = row.in_laboratorio_ciencias
            """,
            iter_query_batches(
                con,
                """
                select ano, id_escola, id_municipio, in_med_padronizado,
                       in_prof_tec, prop_mat_em_integral_escola, qt_mat_med_compat,
                       in_internet_aprendizagem, in_biblioteca, in_laboratorio_ciencias,
                       tem_em_e_tecnico_no_mesmo_ano, tem_em_e_tecnico_no_nem
                from srv_escola_ano_em_tecnico
                """,
            ),
            'ofertas por escola e ano',
        )
    driver.close()


def validate(con: duckdb.DuckDBPyConnection) -> None:
    missing = [
        table
        for table in SERVING_TABLES
        if con.execute(
            'select count(*) from information_schema.tables where table_name = ?',
            [table],
        ).fetchone()[0] == 0
    ]
    if missing:
        raise RuntimeError(f'Tabelas serving ausentes: {", ".join(missing)}')

    with MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000) as client:
        client.admin.command('ping')
    print('MongoDB: conexão OK', flush=True)

    with GraphDatabase.driver(
        NEO4J_URI,
        auth=(NEO4J_USER, NEO4J_PASSWORD),
        connection_timeout=5,
    ) as driver:
        driver.verify_connectivity()
    print('Neo4j: conexão OK', flush=True)

    for table in SERVING_TABLES:
        count = con.execute(f'select count(*) from {table}').fetchone()[0]
        print(f'DuckDB: {table} - {count} registros', flush=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Publica a camada serving do DuckDB no MongoDB e Neo4j.',
    )
    parser.add_argument(
        '--check-only',
        action='store_true',
        help='Valida tabelas e conexões sem gravar dados.',
    )
    parser.add_argument(
        '--target',
        choices=('all', 'mongodb', 'neo4j'),
        default='all',
        help='Destino da publicação (padrão: all).',
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not DUCKDB_PATH.exists():
        raise FileNotFoundError(f'DuckDB não encontrado em {DUCKDB_PATH}')
    with duckdb.connect(str(DUCKDB_PATH), read_only=True) as con:
        validate(con)
        if not args.check_only:
            if args.target in ('all', 'mongodb'):
                export_mongo(con)
            if args.target in ('all', 'neo4j'):
                export_neo4j(con)


if __name__ == '__main__':
    main()
