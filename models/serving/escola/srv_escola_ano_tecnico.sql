{{ config(materialized='table') }}

with tecnico as (
    select *
    from {{ ref('int_censo_curso_tecnico_escola_ano_2023_2025') }}
),
municipio as (
    select
        ano,
        id_municipio,
        nome_municipio,
        id_uf,
        sigla_uf,
        nome_uf,
        nome_regiao,
        capital_uf,
        amazonia_legal,
        pib,
        tem_pib_no_ano,
        populacao,
        taxa_alfabetizacao,
        taxa_alfabetizacao_detalhada_calculada,
        ano_saeb_referencia,
        tem_saeb_no_ano_flag,
        media_12_lp,
        media_12_mt,
        media_12_lp_mt
    from {{ ref('int_municipio_ano_painel_educacional') }}
)

select
    tecnico.ano,
    tecnico.id_municipio,
    municipio.nome_municipio,
    municipio.id_uf,
    municipio.sigla_uf,
    municipio.nome_uf,
    municipio.nome_regiao,
    municipio.capital_uf,
    municipio.amazonia_legal,
    tecnico.tp_dependencia,
    tecnico.tp_localizacao,
    tecnico.no_entidade,
    tecnico.id_escola,
    tecnico.periodo_nem,
    tecnico.qt_cursos_tecnicos_distintos,
    tecnico.qt_areas_tecnicas_distintas,
    tecnico.qt_curso_tec,
    tecnico.qt_mat_curso_tec,
    tecnico.qt_curso_tec_ct,
    tecnico.qt_mat_curso_tec_ct,
    tecnico.qt_curso_tec_nm,
    tecnico.qt_mat_curso_tec_nm,
    tecnico.qt_curso_tec_conc,
    tecnico.qt_mat_curso_tec_conc,
    tecnico.qt_curso_tec_subs,
    tecnico.qt_mat_curso_tec_subs,
    tecnico.qt_curso_tec_eja,
    tecnico.qt_mat_curso_tec_eja,
    tecnico.qt_curso_tec_iftp,
    tecnico.qt_mat_curso_tec_iftp,
    tecnico.qt_curso_tec_iftp_ct,
    tecnico.qt_mat_curso_tec_iftp_ct,
    tecnico.in_oferta_curso_tecnico,
    tecnico.in_oferta_curso_tecnico_nem,
    municipio.ano_saeb_referencia,
    municipio.tem_saeb_no_ano_flag,
    municipio.pib,
    municipio.tem_pib_no_ano,
    municipio.populacao,
    municipio.taxa_alfabetizacao,
    municipio.taxa_alfabetizacao_detalhada_calculada,
    municipio.media_12_lp,
    municipio.media_12_mt,
    municipio.media_12_lp_mt
from tecnico
left join municipio
    on tecnico.ano = municipio.ano
   and tecnico.id_municipio = municipio.id_municipio
