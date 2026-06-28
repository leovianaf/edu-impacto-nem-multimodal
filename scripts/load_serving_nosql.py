from __future__ import annotations

import os
from pathlib import Path

import duckdb
import pandas as pd
from neo4j import GraphDatabase
from pymongo import MongoClient, ReplaceOne

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DUCKDB_PATH = PROJECT_ROOT / 'edu_impacto_nem_multimodal.duckdb'
SERVING_TABLES = [
    'srv_municipio_ano_painel_educacional',
    'srv_municipio_ano_nem',
    'srv_municipio_ano_tecnico',
    'srv_escola_ano_em',
    'srv_escola_ano_tecnico',
    'srv_escola_ano_em_tecnico',
]

MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017')
MONGO_DB = os.getenv('MONGO_DB', 'edu_impacto_nem')
NEO4J_URI = os.getenv('NEO4J_URI', 'bolt://localhost:7687')
NEO4J_USER = os.getenv('NEO4J_USER', 'neo4j')
NEO4J_PASSWORD = os.getenv('NEO4J_PASSWORD', 'neo4j')


def read_table(con: duckdb.DuckDBPyConnection, table_name: str) -> pd.DataFrame:
    return con.execute(f'select * from {table_name}').fetchdf()


def clean_records(df: pd.DataFrame) -> list[dict]:
    return df.where(pd.notnull(df), None).to_dict('records')


def export_mongo(con: duckdb.DuckDBPyConnection) -> None:
    client = MongoClient(MONGO_URI)
    db = client[MONGO_DB]

    keys_by_table = {
        'srv_municipio_ano_painel_educacional': ['ano', 'id_municipio'],
        'srv_municipio_ano_nem': ['ano', 'id_municipio'],
        'srv_municipio_ano_tecnico': ['ano', 'id_municipio'],
        'srv_escola_ano_em': ['ano', 'id_municipio', 'id_escola'],
        'srv_escola_ano_tecnico': ['ano', 'id_municipio', 'id_escola', 'id_area_curso_profissional', 'co_curso_educ_profissional'],
        'srv_escola_ano_em_tecnico': ['ano', 'id_municipio', 'id_escola'],
    }

    for table_name in SERVING_TABLES:
        df = read_table(con, table_name)
        if df.empty:
            continue
        ops = []
        for row in clean_records(df):
            query = {key: row[key] for key in keys_by_table[table_name]}
            ops.append(ReplaceOne(query, row, upsert=True))
        if ops:
            db[table_name].bulk_write(ops)

    client.close()


def export_neo4j(con: duckdb.DuckDBPyConnection) -> None:
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    with driver.session() as session:
        session.run('CREATE CONSTRAINT municipio_id IF NOT EXISTS FOR (m:Municipio) REQUIRE m.id_municipio IS UNIQUE')
        session.run('CREATE CONSTRAINT escola_id IF NOT EXISTS FOR (e:Escola) REQUIRE e.id_escola IS UNIQUE')
        session.run('CREATE CONSTRAINT ano_id IF NOT EXISTS FOR (a:Ano) REQUIRE a.ano IS UNIQUE')

        municipios = con.execute(
            """
            select distinct id_municipio, nome_municipio, id_uf, sigla_uf, nome_uf, nome_regiao, capital_uf, amazonia_legal
            from srv_municipio_ano_painel_educacional
            """
        ).fetchdf()
        for row in clean_records(municipios):
            session.run(
                """
                MERGE (m:Municipio {id_municipio: $id_municipio})
                SET m.nome_municipio = $nome_municipio,
                    m.id_uf = $id_uf,
                    m.sigla_uf = $sigla_uf,
                    m.nome_uf = $nome_uf,
                    m.nome_regiao = $nome_regiao,
                    m.capital_uf = $capital_uf,
                    m.amazonia_legal = $amazonia_legal
                """,
                **row,
            )

        anos = con.execute('select distinct ano from srv_municipio_ano_painel_educacional').fetchdf()
        for row in clean_records(anos):
            session.run('MERGE (a:Ano {ano: $ano})', **row)

        municipios_ano = con.execute(
            """
            select ano, id_municipio, periodo_nem, tem_saeb_no_ano_flag, prop_mat_em_tecnico_profissional, prop_escolas_com_curso_tecnico
            from srv_municipio_ano_painel_educacional
            """
        ).fetchdf()
        for row in clean_records(municipios_ano):
            session.run(
                """
                MATCH (m:Municipio {id_municipio: $id_municipio})
                MATCH (a:Ano {ano: $ano})
                MERGE (m)-[r:PAINEL_MUNICIPAL]->(a)
                SET r.periodo_nem = $periodo_nem,
                    r.tem_saeb_no_ano_flag = $tem_saeb_no_ano_flag,
                    r.prop_mat_em_tecnico_profissional = $prop_mat_em_tecnico_profissional,
                    r.prop_escolas_com_curso_tecnico = $prop_escolas_com_curso_tecnico
                """,
                **row,
            )

        escolas = con.execute(
            """
            select distinct id_escola, no_entidade, id_municipio, nome_municipio, sigla_uf
            from srv_escola_ano_em_tecnico
            """
        ).fetchdf()
        for row in clean_records(escolas):
            session.run(
                """
                MERGE (e:Escola {id_escola: $id_escola})
                SET e.no_entidade = $no_entidade,
                    e.id_municipio = $id_municipio,
                    e.nome_municipio = $nome_municipio,
                    e.sigla_uf = $sigla_uf
                """,
                **row,
            )
            session.run(
                """
                MATCH (e:Escola {id_escola: $id_escola})
                MATCH (m:Municipio {id_municipio: $id_municipio})
                MERGE (e)-[:PERTENCE_A]->(m)
                """,
                **row,
            )

        escola_ano = con.execute(
            """
            select ano, id_escola, id_municipio, tem_em_e_tecnico_no_mesmo_ano, tem_em_e_tecnico_no_nem
            from srv_escola_ano_em_tecnico
            """
        ).fetchdf()
        for row in clean_records(escola_ano):
            session.run(
                """
                MATCH (e:Escola {id_escola: $id_escola})
                MATCH (a:Ano {ano: $ano})
                MERGE (e)-[r:OFERTA_EM_TECNICO]->(a)
                SET r.tem_em_e_tecnico_no_mesmo_ano = $tem_em_e_tecnico_no_mesmo_ano,
                    r.tem_em_e_tecnico_no_nem = $tem_em_e_tecnico_no_nem,
                    r.id_municipio = $id_municipio
                """,
                **row,
            )

    driver.close()


def main() -> None:
    if not DUCKDB_PATH.exists():
        raise FileNotFoundError(f'DuckDB não encontrado em {DUCKDB_PATH}')
    con = duckdb.connect(str(DUCKDB_PATH), read_only=True)
    export_mongo(con)
    export_neo4j(con)


if __name__ == '__main__':
    main()
