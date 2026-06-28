
"""Exporta o dicionário da camada serving para XLSX.

Cada tabela da serving vira uma aba separada com colunas, tipos, nulabilidade,
descrição do dbt e marcação simples dos testes declarados no manifest.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import duckdb
import pandas as pd


DEFAULT_MODELS = [
    'srv_municipio_ano_painel_educacional',
    'srv_municipio_ano_nem',
    'srv_municipio_ano_tecnico',
    'srv_escola_ano_em',
    'srv_escola_ano_tecnico',
    'srv_escola_ano_em_tecnico',
]

SHEET_NAMES = {
    'srv_municipio_ano_painel_educacional': 'mun_painel',
    'srv_municipio_ano_nem': 'mun_nem',
    'srv_municipio_ano_tecnico': 'mun_tecnico',
    'srv_escola_ano_em': 'esc_em',
    'srv_escola_ano_tecnico': 'esc_tecnico',
    'srv_escola_ano_em_tecnico': 'esc_em_tecnico',
}


def project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def safe_sheet_name(name: str, used: set[str]) -> str:
    base = re.sub(r'[^A-Za-z0-9_]+', '_', name)[:31]
    if not base:
        base = 'sheet'
    candidate = base
    suffix = 1
    while candidate in used:
        trim = max(0, 31 - len(str(suffix)) - 1)
        candidate = f"{base[:trim]}_{suffix}"
        suffix += 1
    used.add(candidate)
    return candidate


def load_manifest(manifest_path: Path) -> dict:
    return json.loads(manifest_path.read_text(encoding='utf-8'))


def node(manifest: dict, model_name: str) -> dict:
    return manifest['nodes'][f'model.edu_impacto_nem_multimodal.{model_name}']


DERIVED_COLUMN_DESCRIPTIONS = {
    'pib_per_capita': 'PIB municipal dividido pela população residente.',
    'qt_mat_med_por_mil_hab': 'Quantidade de matrículas de ensino médio por mil habitantes.',
    'qt_mat_med_nm_por_mil_hab': 'Quantidade de matrículas de ensino médio NM por mil habitantes.',
    'qt_mat_med_iftp_ct_por_mil_hab': 'Quantidade de matrículas de ensino médio em itinerário técnico CT por mil habitantes.',
    'qt_mat_med_iftp_qp_por_mil_hab': 'Quantidade de matrículas de ensino médio em itinerário técnico QP por mil habitantes.',
    'prop_mat_em_integral': 'Proporção de matrículas de ensino médio em tempo integral no município.',
    'prop_mat_em_tecnico_profissional': 'Proporção de matrículas de ensino médio associadas ao eixo técnico-profissional.',
    'prop_escolas_em_integral': 'Proporção de escolas de ensino médio em tempo integral no município.',
    'prop_escolas_itinerario_tecn_prof': 'Proporção de escolas de ensino médio com itinerário técnico-profissional.',
    'prop_escolas_com_curso_tecnico': 'Proporção de escolas com oferta de curso técnico no município.',
    'prop_escolas_em_com_curso_tecnico': 'Proporção de escolas de ensino médio com oferta de curso técnico no município.',
    'tem_em_e_tecnico_no_mesmo_ano': 'Flag que indica coexistência de ensino médio e curso técnico na mesma escola e ano.',
    'tem_em_e_tecnico_no_nem': 'Flag que indica coexistência de ensino médio e curso técnico no recorte do NEM na mesma escola e ano.',
    'tem_saeb_no_ano_flag': 'Flag indicando se o SAEB vigente no ciclo foi observado naquele ano.',
    'tem_saeb_no_ciclo': 'Flag indicando se existe SAEB vigente no ciclo anual.',
    'ano_saeb_referencia': 'Ano da edição SAEB usada como referência no ciclo.',
    'in_ano_edicao_saeb': 'Flag que indica o ano original de aplicação do SAEB.',
    'in_ano_vigencia_ciclo': 'Flag que indica que a linha pertence ao ano em que o SAEB permanece vigente no ciclo.',
    'saeb_dependencia_adm_canonica': 'Dependência administrativa padronizada para o recorte canônico do SAEB.',
    'saeb_localizacao_canonica': 'Localização padronizada para o recorte canônico do SAEB.',
}


def column_description(manifest: dict, model_name: str, column_name: str) -> str:
    visited: set[str] = set()

    def _resolve(current_model: str) -> str:
        if current_model in visited:
            return ''
        visited.add(current_model)
        current = node(manifest, current_model)
        direct = (current.get('columns', {}).get(column_name, {}) or {}).get('description', '') or ''
        if direct.strip():
            return direct.strip()

        for upstream in current.get('depends_on', {}).get('nodes', []) or []:
            if not upstream.startswith('model.'):
                continue
            upstream_node = manifest.get('nodes', {}).get(upstream) or {}
            upstream_model = upstream_node.get('name')
            if not upstream_model:
                continue
            upstream_desc = (upstream_node.get('columns', {}).get(column_name, {}) or {}).get('description', '') or ''
            if upstream_desc.strip():
                return upstream_desc.strip()
            resolved = _resolve(upstream_model)
            if resolved.strip():
                return resolved.strip()
        return ''

    return _resolve(model_name)


def column_tests(manifest: dict, model_name: str, column_name: str) -> str:
    uid = f'model.edu_impacto_nem_multimodal.{model_name}'
    tests = []
    for test_id in manifest.get('child_map', {}).get(uid, []):
        test_node = manifest.get('nodes', {}).get(test_id, {})
        test_meta = test_node.get('test_metadata') or {}
        kwargs = test_meta.get('kwargs') or {}
        if kwargs.get('column_name') != column_name:
            continue
        name = test_meta.get('name') or test_node.get('name')
        if name:
            tests.append(name)
    return ', '.join(sorted(dict.fromkeys(tests)))


def column_inventory(con: duckdb.DuckDBPyConnection, manifest: dict, model_name: str) -> pd.DataFrame:
    declared_cols = node(manifest, model_name).get('columns', {})
    physical = con.execute(
        f"""
        select column_name, data_type, is_nullable, ordinal_position
        from information_schema.columns
        where table_schema = 'main'
          and table_name = '{model_name}'
        order by ordinal_position
        """
    ).fetchdf()

    rows = []
    for _, row in physical.iterrows():
        col_name = row['column_name']
        meta = declared_cols.get(col_name, {})
        rows.append(
            {
                'coluna': col_name,
                'tipo_fisico': row['data_type'],
                'pode_ser_nulo': row['is_nullable'],
                'descricao': column_description(manifest, model_name, col_name) or DERIVED_COLUMN_DESCRIPTIONS.get(col_name, ''),
                'testes_dbt': column_tests(manifest, model_name, col_name),
                'not_null': any((t.get('name') == 'not_null') for t in meta.get('tests', []) or []),
                'accepted_values': any((t.get('name') == 'accepted_values') for t in meta.get('tests', []) or []),
                'relationships': any((t.get('name') == 'relationships') for t in meta.get('tests', []) or []),
            }
        )
    return pd.DataFrame(rows)


def table_summary(con: duckdb.DuckDBPyConnection, manifest: dict, model_name: str) -> dict:
    node_meta = node(manifest, model_name)
    row_count = con.execute(f"select count(*) from {model_name}").fetchone()[0]
    col_count = con.execute(
        f"""
        select count(*)
        from information_schema.columns
        where table_schema = 'main'
          and table_name = '{model_name}'
        """
    ).fetchone()[0]
    return {
        'tabela': model_name,
        'sheet': SHEET_NAMES.get(model_name, model_name[:31]),
        'materialized': node_meta.get('config', {}).get('materialized'),
        'descricao': node_meta.get('description', ''),
        'linhas': row_count,
        'colunas': col_count,
    }


def write_excel(output_path: Path, summary: pd.DataFrame, inventories: dict[str, pd.DataFrame]) -> None:
    used_sheet_names: set[str] = set()
    with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
        summary.to_excel(writer, sheet_name='resumo', index=False)
        used_sheet_names.add('resumo')
        for model_name, df in inventories.items():
            sheet_name = safe_sheet_name(SHEET_NAMES.get(model_name, model_name), used_sheet_names)
            df.to_excel(writer, sheet_name=sheet_name, index=False)

        workbook = writer.book
        for ws in workbook.worksheets:
            ws.freeze_panes = 'A2'
            ws.auto_filter.ref = ws.dimensions
            for column_cells in ws.columns:
                values = [str(cell.value) if cell.value is not None else '' for cell in column_cells[:200]]
                width = min(max(len(v) for v in values) + 2 if values else 10, 60)
                ws.column_dimensions[column_cells[0].column_letter].width = width


def main() -> None:
    parser = argparse.ArgumentParser(description='Exporta o dicionário da serving para XLSX.')
    parser.add_argument('--database-path', type=Path, default=project_root() / 'edu_impacto_nem_multimodal.duckdb')
    parser.add_argument('--manifest-path', type=Path, default=project_root() / 'target' / 'manifest.json')
    parser.add_argument('--output', type=Path, default=project_root() / 'docs' / 'Dicionario_Serving.xlsx')
    parser.add_argument('--models', nargs='*', default=DEFAULT_MODELS)
    args = parser.parse_args()

    if not args.database_path.exists():
        raise FileNotFoundError(f'Banco DuckDB não encontrado em {args.database_path}')
    if not args.manifest_path.exists():
        raise FileNotFoundError(f'manifest.json não encontrado em {args.manifest_path}')

    manifest = load_manifest(args.manifest_path)
    con = duckdb.connect(str(args.database_path), read_only=True)

    summary_rows = []
    inventories: dict[str, pd.DataFrame] = {}
    for model_name in args.models:
        summary_rows.append(table_summary(con, manifest, model_name))
        inventories[model_name] = column_inventory(con, manifest, model_name)

    summary = pd.DataFrame(summary_rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    write_excel(args.output, summary, inventories)
    print(f'Dicionário da serving salvo em {args.output}')


if __name__ == '__main__':
    main()

