"""Gera um pacote autocontido da camada serving para depósito no Zenodo.

O pacote contém as seis tabelas finais em Parquet, metadados tabulares,
uma versão enriquecida do Dicionario_Serving.xlsx, relatório de qualidade,
README, licença de dados e checksums SHA-256.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
from pathlib import Path

import duckdb
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]

TABLES = [
    "srv_municipio_ano_painel_educacional",
    "srv_municipio_ano_nem",
    "srv_municipio_ano_tecnico",
    "srv_escola_ano_em",
    "srv_escola_ano_tecnico",
    "srv_escola_ano_em_tecnico",
]

SHEET_NAMES = {
    "srv_municipio_ano_painel_educacional": "mun_painel",
    "srv_municipio_ano_nem": "mun_nem",
    "srv_municipio_ano_tecnico": "mun_tecnico",
    "srv_escola_ano_em": "esc_em",
    "srv_escola_ano_tecnico": "esc_tecnico",
    "srv_escola_ano_em_tecnico": "esc_em_tecnico",
}

NATURAL_KEYS = {
    "srv_municipio_ano_painel_educacional": ["ano", "id_municipio"],
    "srv_municipio_ano_nem": ["ano", "id_municipio"],
    "srv_municipio_ano_tecnico": ["ano", "id_municipio"],
    "srv_escola_ano_em": ["ano", "id_municipio", "id_escola"],
    "srv_escola_ano_tecnico": ["ano", "id_municipio", "id_escola"],
    "srv_escola_ano_em_tecnico": ["ano", "id_municipio", "id_escola"],
}

GRAINS = {
    table: ("municipio/ano" if table.startswith("srv_municipio") else "escola/ano")
    for table in TABLES
}

FOCUS = {
    "srv_municipio_ano_painel_educacional": (
        "Painel municipal integrado com NEM, SAEB, oferta educacional, "
        "educação técnica, PIB e alfabetização."
    ),
    "srv_municipio_ano_nem": (
        "Recorte municipal para análises de Ensino Médio, NEM, estrutura, "
        "matrículas, SAEB e contexto."
    ),
    "srv_municipio_ano_tecnico": (
        "Oferta, presença e intensidade da educação profissional e técnica "
        "por município e ano."
    ),
    "srv_escola_ano_em": (
        "Estrutura, infraestrutura, oferta e matrículas das escolas com "
        "Ensino Médio."
    ),
    "srv_escola_ano_tecnico": (
        "Oferta de cursos técnicos e matrículas profissionais por escola e ano."
    ),
    "srv_escola_ano_em_tecnico": (
        "Coexistência de Ensino Médio e educação técnica na mesma escola e ano."
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Exporta a serving e seus metadados para um pacote Zenodo."
    )
    parser.add_argument(
        "--database-path",
        type=Path,
        default=PROJECT_ROOT / "edu_impacto_nem_multimodal.duckdb",
    )
    parser.add_argument(
        "--dictionary-path",
        type=Path,
        default=PROJECT_ROOT / "docs" / "Dicionario_Serving.xlsx",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=PROJECT_ROOT / "data" / "zenodo",
    )
    parser.add_argument("--version", default="1.0.0")
    parser.add_argument("--compression", default="zstd")
    parser.add_argument("--data-license", default="CC-BY-4.0")
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Substitui o diretório da mesma versão caso ele já exista.",
    )
    return parser.parse_args()


def sql_identifier(value: str) -> str:
    if value not in TABLES:
        raise ValueError(f"Tabela não permitida: {value}")
    return f'"{value}"'


def sql_literal(value: str | Path) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def require_inputs(database_path: Path, dictionary_path: Path) -> None:
    if not database_path.is_file():
        raise FileNotFoundError(f"DuckDB não encontrado: {database_path}")
    if not dictionary_path.is_file():
        raise FileNotFoundError(f"Dicionário da serving não encontrado: {dictionary_path}")


def prepare_output(output_dir: Path, overwrite: bool) -> tuple[Path, Path]:
    if output_dir.exists():
        if not overwrite:
            raise FileExistsError(
                f"O pacote já existe em {output_dir}. Use --overwrite para substituí-lo."
            )
        shutil.rmtree(output_dir)
    data_dir = output_dir / "data"
    metadata_dir = output_dir / "metadata"
    data_dir.mkdir(parents=True)
    metadata_dir.mkdir()
    return data_dir, metadata_dir


def assert_tables_exist(con: duckdb.DuckDBPyConnection) -> None:
    existing = {
        row[0]
        for row in con.execute(
            """
            select table_name
            from information_schema.tables
            where table_schema = 'main'
            """
        ).fetchall()
    }
    missing = sorted(set(TABLES) - existing)
    if missing:
        raise RuntimeError(f"Tabelas serving ausentes no DuckDB: {', '.join(missing)}")


def export_parquets(
    con: duckdb.DuckDBPyConnection, data_dir: Path, compression: str
) -> dict[str, Path]:
    allowed_compressions = {"uncompressed", "snappy", "gzip", "zstd", "brotli", "lz4"}
    compression = compression.lower()
    if compression not in allowed_compressions:
        raise ValueError(
            f"Compressão inválida: {compression}. "
            f"Use uma de: {', '.join(sorted(allowed_compressions))}"
        )

    exports: dict[str, Path] = {}
    for table in TABLES:
        output_path = data_dir / f"{table}.parquet"
        con.execute(
            f"""
            copy (select * from {sql_identifier(table)})
            to {sql_literal(output_path)}
            (format parquet, compression {compression})
            """
        )
        exports[table] = output_path
        print(f"Parquet gerado: {output_path.name}")
    return exports


def load_base_dictionary(
    dictionary_path: Path,
) -> tuple[pd.DataFrame, dict[str, pd.DataFrame]]:
    workbook = pd.ExcelFile(dictionary_path)
    required_sheets = {"resumo", *SHEET_NAMES.values()}
    missing = sorted(required_sheets - set(workbook.sheet_names))
    if missing:
        raise ValueError(
            "O Dicionario_Serving.xlsx não contém as abas esperadas: "
            + ", ".join(missing)
        )

    summary = pd.read_excel(workbook, sheet_name="resumo")
    inventories = {
        table: pd.read_excel(workbook, sheet_name=sheet)
        for table, sheet in SHEET_NAMES.items()
    }
    return summary, inventories


def physical_columns(
    con: duckdb.DuckDBPyConnection, table: str
) -> pd.DataFrame:
    return con.execute(
        """
        select
            column_name as coluna,
            data_type as tipo_fisico_atual,
            is_nullable as pode_ser_nulo_atual,
            ordinal_position as posicao
        from information_schema.columns
        where table_schema = 'main' and table_name = ?
        order by ordinal_position
        """,
        [table],
    ).fetchdf()


def enrich_dictionary(
    con: duckdb.DuckDBPyConnection,
    base_summary: pd.DataFrame,
    base_inventories: dict[str, pd.DataFrame],
) -> tuple[pd.DataFrame, pd.DataFrame, dict[str, pd.DataFrame]]:
    summary_by_table = (
        base_summary.set_index("tabela").to_dict(orient="index")
        if "tabela" in base_summary.columns
        else {}
    )
    summary_rows: list[dict] = []
    flattened: list[pd.DataFrame] = []
    enriched: dict[str, pd.DataFrame] = {}

    for table in TABLES:
        physical = physical_columns(con, table)
        base = base_inventories[table].copy()
        if "coluna" not in base.columns:
            raise ValueError(f"A aba {SHEET_NAMES[table]} não contém a coluna 'coluna'.")

        duplicate_columns = base.loc[base["coluna"].duplicated(), "coluna"].tolist()
        if duplicate_columns:
            raise ValueError(
                f"Colunas duplicadas no dicionário de {table}: {duplicate_columns}"
            )

        current_names = set(physical["coluna"])
        documented_names = set(base["coluna"])
        if current_names != documented_names:
            missing_in_dictionary = sorted(current_names - documented_names)
            stale_in_dictionary = sorted(documented_names - current_names)
            raise ValueError(
                f"Dicionário desatualizado para {table}. "
                f"Ausentes: {missing_in_dictionary}; excedentes: {stale_in_dictionary}"
            )

        df = physical.merge(base, on="coluna", how="left", validate="one_to_one")
        keys = NATURAL_KEYS[table]
        df["tabela"] = table
        df["grao"] = GRAINS[table]
        df["papel_na_chave"] = df["coluna"].map(
            lambda col: (
                f"chave_natural_{keys.index(col) + 1}"
                if col in keys
                else (
                    "chave_de_ligacao"
                    if col in {"ano", "id_municipio", "id_escola"}
                    else "atributo"
                )
            )
        )
        df["usada_para_ligacao"] = df["coluna"].isin(
            {"ano", "id_municipio", "id_escola"}
        )
        preferred_order = [
            "tabela",
            "grao",
            "posicao",
            "coluna",
            "tipo_fisico_atual",
            "pode_ser_nulo_atual",
            "papel_na_chave",
            "usada_para_ligacao",
            "descricao",
            "testes_dbt",
            "not_null",
            "accepted_values",
            "relationships",
        ]
        remaining = [column for column in df.columns if column not in preferred_order]
        df = df[[column for column in preferred_order if column in df.columns] + remaining]
        enriched[table] = df
        flattened.append(df)

        base_meta = summary_by_table.get(table, {})
        summary_rows.append(
            {
                "tabela": table,
                "aba_dicionario": SHEET_NAMES[table],
                "grao": GRAINS[table],
                "chave_natural": " + ".join(keys),
                "foco": FOCUS[table],
                "descricao_original": base_meta.get("descricao", ""),
                "linhas": con.execute(
                    f"select count(*) from {sql_identifier(table)}"
                ).fetchone()[0],
                "colunas": len(physical),
            }
        )

    return pd.DataFrame(summary_rows), pd.concat(flattened, ignore_index=True), enriched


def relationships_metadata() -> pd.DataFrame:
    rows: list[dict[str, str]] = []

    municipal = [table for table in TABLES if table.startswith("srv_municipio")]
    school = [table for table in TABLES if table.startswith("srv_escola")]

    for index, source in enumerate(municipal):
        for target in municipal[index + 1 :]:
            rows.append(
                {
                    "tabela_origem": source,
                    "tabela_destino": target,
                    "cardinalidade_esperada": "1:0..1",
                    "colunas_origem": "ano + id_municipio",
                    "colunas_destino": "ano + id_municipio",
                    "tipo_join_recomendado": "LEFT JOIN a partir da tabela de interesse",
                    "observacao": (
                        "As tabelas possuem o mesmo grão, mas a cobertura pode variar; "
                        "não presuma correspondência obrigatória em todos os anos."
                    ),
                }
            )

    for index, source in enumerate(school):
        for target in school[index + 1 :]:
            rows.append(
                {
                    "tabela_origem": source,
                    "tabela_destino": target,
                    "cardinalidade_esperada": "1:0..1",
                    "colunas_origem": "ano + id_municipio + id_escola",
                    "colunas_destino": "ano + id_municipio + id_escola",
                    "tipo_join_recomendado": "LEFT JOIN a partir da tabela de interesse",
                    "observacao": (
                        "As tabelas possuem o mesmo grão, mas tabelas técnicas têm "
                        "cobertura temporal e populacional mais restrita."
                    ),
                }
            )

    for source in school:
        for target in municipal:
            rows.append(
                {
                    "tabela_origem": source,
                    "tabela_destino": target,
                    "cardinalidade_esperada": "N:0..1",
                    "colunas_origem": "ano + id_municipio",
                    "colunas_destino": "ano + id_municipio",
                    "tipo_join_recomendado": "LEFT JOIN da escola para o município",
                    "observacao": (
                        "O vínculo agrega contexto municipal à escola. Não inclua "
                        "id_escola na ligação com tabelas municipais."
                    ),
                }
            )
    return pd.DataFrame(rows)


def quality_report(
    con: duckdb.DuckDBPyConnection, parquet_paths: dict[str, Path]
) -> pd.DataFrame:
    rows = []
    for table in TABLES:
        keys = NATURAL_KEYS[table]
        key_expr = ", ".join(f'"{key}"' for key in keys)
        null_expr = " or ".join(f'"{key}" is null' for key in keys)
        entity_column = "id_municipio" if GRAINS[table] == "municipio/ano" else "id_escola"
        stats = con.execute(
            f"""
            select
                count(*) as linhas,
                count(*) - count(distinct ({key_expr})) as chaves_duplicadas,
                count(*) filter (where {null_expr}) as chaves_nulas,
                count(distinct "{entity_column}") as entidades_distintas,
                min(ano) as ano_minimo,
                max(ano) as ano_maximo
            from {sql_identifier(table)}
            """
        ).fetchone()
        parquet_rows = con.execute(
            f"select count(*) from read_parquet({sql_literal(parquet_paths[table])})"
        ).fetchone()[0]
        column_count = con.execute(
            """
            select count(*)
            from information_schema.columns
            where table_schema = 'main' and table_name = ?
            """,
            [table],
        ).fetchone()[0]
        rows.append(
            {
                "tabela": table,
                "grao": GRAINS[table],
                "chave_natural": " + ".join(keys),
                "linhas_duckdb": stats[0],
                "linhas_parquet": parquet_rows,
                "colunas": column_count,
                "chaves_duplicadas": stats[1],
                "chaves_nulas": stats[2],
                "entidades_distintas": stats[3],
                "ano_minimo": stats[4],
                "ano_maximo": stats[5],
                "parquet_confere": stats[0] == parquet_rows,
                "qualidade_chave_aprovada": stats[1] == 0 and stats[2] == 0,
            }
        )
    return pd.DataFrame(rows)


def write_enriched_dictionary(
    output_path: Path,
    summary: pd.DataFrame,
    inventories: dict[str, pd.DataFrame],
    relationships: pd.DataFrame,
) -> None:
    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        summary.to_excel(writer, sheet_name="resumo", index=False)
        relationships.to_excel(writer, sheet_name="relacionamentos", index=False)
        for table, dataframe in inventories.items():
            dataframe.to_excel(
                writer, sheet_name=SHEET_NAMES[table], index=False
            )

        for worksheet in writer.book.worksheets:
            worksheet.freeze_panes = "A2"
            worksheet.auto_filter.ref = worksheet.dimensions
            for cells in worksheet.columns:
                sampled = [
                    str(cell.value) if cell.value is not None else ""
                    for cell in cells[:200]
                ]
                width = min(max((len(value) for value in sampled), default=8) + 2, 70)
                worksheet.column_dimensions[cells[0].column_letter].width = width


def write_readme(
    output_path: Path,
    version: str,
    data_license: str,
    inventory: pd.DataFrame,
) -> None:
    table_lines = "\n".join(
        f"| `{row.tabela}` | {row.grao} | {row.linhas:,} | {row.colunas} | {row.foco} |"
        for row in inventory.itertuples(index=False)
    )
    content = f"""# Dataset analítico sobre Ensino Médio, NEM, SAEB e educação técnica

Versão: {version}

## Conteúdo

Este depósito contém a camada final (`serving`) do pipeline analítico. As
tabelas estão em Parquet com compressão ZSTD e preservam tipos e valores nulos.

| Tabela | Grão | Linhas | Colunas | Foco |
|---|---|---:|---:|---|
{table_lines}

## Como relacionar as tabelas

- Entre tabelas municipais: `ano + id_municipio`.
- Entre tabelas escolares: `ano + id_municipio + id_escola`.
- De escola para município: `ano + id_municipio`.
- Use `LEFT JOIN` a partir da população da análise, porque as tabelas técnicas
  têm cobertura mais restrita.

O arquivo `metadata/relacionamentos_tabelas.csv` e a aba `relacionamentos` do
dicionário detalham todas as combinações recomendadas.

## Metadados e qualidade

- `metadata/inventario_tabelas.csv`: volume, grão, chave e foco.
- `metadata/dicionario_colunas.csv`: dicionário consolidado das 521 colunas.
- `metadata/Dicionario_Serving_Zenodo.xlsx`: versão navegável do dicionário.
- `metadata/relacionamentos_tabelas.csv`: chaves e cardinalidades esperadas.
- `metadata/relatorio_qualidade.csv`: completude e unicidade das chaves,
  cobertura temporal e conferência entre DuckDB e Parquet.
- `SHA256SUMS`: integridade dos arquivos do pacote.

## Leitura rápida

Python:

```python
import pandas as pd
df = pd.read_parquet("data/srv_municipio_ano_painel_educacional.parquet")
```

DuckDB:

```sql
select *
from read_parquet('data/srv_municipio_ano_painel_educacional.parquet');
```

## Fontes

- INEP: Censo Escolar 2019–2025.
- INEP: resultados municipais do SAEB 2019, 2021 e 2023.
- IBGE: PIB municipal 2019–2023 e Censo Demográfico 2022.
- Diretório de municípios usado para harmonização territorial.

## Limitações

- O desenho é observacional; associações não identificam causalidade.
- O SAEB está no grão municipal e foi observado apenas em 2019, 2021 e 2023.
- Valores vigentes por ciclo não representam novas aplicações do SAEB.
- Não há fonte direta de abandono, reprovação ou evasão.
- A cobertura detalhada de cursos técnicos concentra-se em 2023–2025.
- Pandemia e diferenças entre redes coincidem com o período analisado.
- As tabelas representam médias e agregações analíticas; consulte o dicionário
  antes de interpretar qualquer indicador.

## Licença

Licença declarada para este pacote: {data_license}. A reutilização deve citar
este depósito e também respeitar e atribuir as fontes originais.
"""
    output_path.write_text(content, encoding="utf-8")


def write_license(output_path: Path, data_license: str) -> None:
    output_path.write_text(
        f"""# Licença dos dados

Identificador informado para o depósito: {data_license}

Este arquivo registra a licença selecionada para o pacote de dados derivados.
Antes da publicação, confirme a compatibilidade dessa licença com os termos de
uso e atribuição das fontes originais (INEP, IBGE e demais fontes citadas).

O código-fonte do projeto possui licença própria e não é relicenciado por este
arquivo.
""",
        encoding="utf-8",
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_checksums(output_dir: Path) -> None:
    checksum_path = output_dir / "SHA256SUMS"
    files = sorted(
        path
        for path in output_dir.rglob("*")
        if path.is_file() and path != checksum_path
    )
    lines = [
        f"{sha256(path)}  {path.relative_to(output_dir).as_posix()}"
        for path in files
    ]
    checksum_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    database_path = args.database_path.resolve()
    dictionary_path = args.dictionary_path.resolve()
    output_dir = (args.output_root / f"v{args.version}").resolve()

    require_inputs(database_path, dictionary_path)
    data_dir, metadata_dir = prepare_output(output_dir, args.overwrite)

    con = duckdb.connect(str(database_path), read_only=True)
    try:
        assert_tables_exist(con)
        parquet_paths = export_parquets(con, data_dir, args.compression)
        base_summary, base_inventories = load_base_dictionary(dictionary_path)
        inventory, columns, inventories = enrich_dictionary(
            con, base_summary, base_inventories
        )
        relationships = relationships_metadata()
        quality = quality_report(con, parquet_paths)
    finally:
        con.close()

    inventory.to_csv(metadata_dir / "inventario_tabelas.csv", index=False)
    columns.to_csv(metadata_dir / "dicionario_colunas.csv", index=False)
    relationships.to_csv(
        metadata_dir / "relacionamentos_tabelas.csv", index=False
    )
    quality.to_csv(metadata_dir / "relatorio_qualidade.csv", index=False)
    write_enriched_dictionary(
        metadata_dir / "Dicionario_Serving_Zenodo.xlsx",
        inventory,
        inventories,
        relationships,
    )
    write_readme(
        output_dir / "README.md", args.version, args.data_license, inventory
    )
    write_license(output_dir / "LICENSE_DATA.md", args.data_license)
    write_checksums(output_dir)

    print(f"\nPacote Zenodo gerado em: {output_dir}")
    print(f"Tabelas exportadas: {len(TABLES)}")
    print(f"Linhas no dicionário consolidado: {len(columns)}")
    print(f"Relacionamentos documentados: {len(relationships)}")


if __name__ == "__main__":
    main()
