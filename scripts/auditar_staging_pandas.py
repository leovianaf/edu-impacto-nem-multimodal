"""Audita as tabelas/views de staging usando DuckDB e Pandas.

Execute depois de materializar a staging com:

    dbt seed --profiles-dir .
    dbt run --select staging --profiles-dir .

Uso:

    python scripts/auditar_staging_pandas.py
    python scripts/auditar_staging_pandas.py --metadata-only
    python scripts/auditar_staging_pandas.py --sample-size 10
    python scripts/auditar_staging_pandas.py --table stg_saeb_resultados_municipios
    python scripts/auditar_staging_pandas.py --with-row-count
    python scripts/auditar_staging_pandas.py --table stg_ibge_pib_municipio --with-null-summary
"""

from __future__ import annotations

import argparse
from pathlib import Path

import duckdb
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = PROJECT_ROOT / "edu_impacto_nem_multimodal.duckdb"

STAGING_TABLES = [
    "stg_saeb_resultados_municipios",
    "stg_censo_escolar_escolas_2019_2024",
    "stg_censo_escolar_2025_escola",
    "stg_censo_escolar_2025_matricula",
    "stg_censo_escolar_2025_curso_tecnico",
    "stg_ibge_pib_municipio",
    "stg_ibge_censo_municipio",
    "stg_ibge_alfabetizacao_detalhada",
    "stg_diretorios_municipio",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Mostra um resumo Pandas das tabelas/views da camada staging."
    )
    parser.add_argument(
        "--database",
        default=str(DEFAULT_DATABASE),
        help="Caminho do arquivo DuckDB criado pelo dbt.",
    )
    parser.add_argument(
        "--table",
        choices=STAGING_TABLES,
        help="Audita apenas uma tabela/view específica da staging.",
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=5,
        help="Quantidade de linhas exibidas na amostra de cada tabela.",
    )
    parser.add_argument(
        "--max-null-columns",
        type=int,
        default=15,
        help="Quantidade máxima de colunas com mais nulos a exibir.",
    )
    parser.add_argument(
        "--with-null-summary",
        action="store_true",
        help="Calcula nulos por coluna. Pode demorar nas views grandes do Censo Escolar.",
    )
    parser.add_argument(
        "--with-row-count",
        action="store_true",
        help="Calcula a quantidade de linhas. Pode demorar nas views grandes do Censo Escolar.",
    )
    parser.add_argument(
        "--metadata-only",
        action="store_true",
        help="Mostra apenas existencia, quantidade de colunas e tipos, sem contar linhas nem buscar amostra.",
    )
    return parser.parse_args()


def table_exists(connection: duckdb.DuckDBPyConnection, table_name: str) -> bool:
    query = """
        select count(*) as total
        from information_schema.tables
        where table_schema = 'main'
          and table_name = ?
    """
    return connection.execute(query, [table_name]).fetchone()[0] > 0


def get_columns(connection: duckdb.DuckDBPyConnection, table_name: str) -> pd.DataFrame:
    query = """
        select
            column_name,
            data_type as column_type,
            is_nullable as nullable
        from information_schema.columns
        where table_schema = 'main'
          and table_name = ?
        order by ordinal_position
    """
    return connection.execute(query, [table_name]).fetchdf()


def get_null_summary(
    connection: duckdb.DuckDBPyConnection,
    table_name: str,
    columns: list[str],
    row_count: int,
) -> pd.DataFrame:
    if row_count == 0:
        return pd.DataFrame(columns=["coluna", "nulos", "pct_nulos"])

    null_expressions = [
        f'sum(case when "{column}" is null then 1 else 0 end) as "{column}"'
        for column in columns
    ]
    null_counts = connection.execute(
        f'select {", ".join(null_expressions)} from "{table_name}"'
    ).fetchdf()

    summary = (
        null_counts.T.reset_index()
        .rename(columns={"index": "coluna", 0: "nulos"})
        .assign(pct_nulos=lambda df: (df["nulos"] / row_count * 100).round(2))
        .sort_values(["nulos", "coluna"], ascending=[False, True])
    )
    return summary


def print_section(title: str) -> None:
    print(f"\n{title}")


def audit_table(
    connection: duckdb.DuckDBPyConnection,
    table_name: str,
    sample_size: int,
    max_null_columns: int,
    with_null_summary: bool,
    with_row_count: bool,
    metadata_only: bool,
) -> None:
    print_section(table_name)

    if not table_exists(connection, table_name):
        print("Tabela/view nao encontrada. Rode `dbt run --select staging --profiles-dir .`.")
        return

    columns_df = get_columns(connection, table_name)
    column_count = len(columns_df)

    row_count = None
    if with_row_count or with_null_summary:
        row_count = connection.execute(f'select count(*) from "{table_name}"').fetchone()[0]
        print(f"linhas: {row_count:,}".replace(",", "."))
    else:
        print("linhas: nao calculado")

    print(f"colunas: {column_count}")

    column_names = columns_df["column_name"].tolist()

    print("\ncolunas e tipos")
    print(columns_df.to_string(index=False))

    if with_null_summary:
        print("\ncolunas com mais nulos")
        if row_count is None:
            row_count = connection.execute(f'select count(*) from "{table_name}"').fetchone()[0]
        null_summary = get_null_summary(connection, table_name, column_names, row_count)
        if null_summary.empty:
            print("sem linhas para avaliar nulos")
        else:
            print(null_summary.head(max_null_columns).to_string(index=False))

    if metadata_only:
        return
    elif sample_size <= 0:
        return
    else:
        print(f"\namostra ({sample_size} linhas)")
        sample = connection.execute(
            f'select * from "{table_name}" limit {sample_size}'
        ).fetchdf()
        print(sample.to_string(index=False))


def main() -> None:
    args = parse_args()
    database_path = Path(args.database)

    if not database_path.exists():
        raise SystemExit(
            f"Banco DuckDB nao encontrado em {database_path}. "
            "Rode `dbt seed --profiles-dir .` e `dbt run --select staging --profiles-dir .` antes."
        )

    tables = [args.table] if args.table else STAGING_TABLES

    with duckdb.connect(str(database_path), read_only=True) as connection:
        for table_name in tables:
            audit_table(
                connection=connection,
                table_name=table_name,
                sample_size=args.sample_size,
                max_null_columns=args.max_null_columns,
                with_null_summary=args.with_null_summary,
                with_row_count=args.with_row_count,
                metadata_only=args.metadata_only,
            )


if __name__ == "__main__":
    main()
