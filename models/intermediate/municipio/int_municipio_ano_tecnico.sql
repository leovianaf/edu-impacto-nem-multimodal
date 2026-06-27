{{ config(materialized='view') }}

with painel_base as (
    select
        ano,
        id_municipio,
        sg_uf,
        no_uf,
        no_municipio,
        periodo_nem,
        qt_escolas,
        qt_escolas_em
    from {{ ref('int_municipio_ano_oferta_educacional') }}
),

tecnico as (
    select
        ano,
        id_municipio,
        min(sg_uf) as sg_uf,
        min(no_uf) as no_uf,
        min(no_municipio) as no_municipio,
        min(periodo_nem) as periodo_nem,
        count(distinct id_escola) as qt_escolas_com_curso_tecnico,
        sum(qt_cursos_tecnicos_distintos) as qt_cursos_tecnicos_distintos,
        sum(qt_areas_tecnicas_distintas) as qt_areas_tecnicas_distintas,
        sum(coalesce(qt_curso_tec, 0)) as qt_curso_tec,
        sum(coalesce(qt_mat_curso_tec, 0)) as qt_mat_curso_tec,
        sum(coalesce(qt_curso_tec_ct, 0)) as qt_curso_tec_ct,
        sum(coalesce(qt_mat_curso_tec_ct, 0)) as qt_mat_curso_tec_ct,
        sum(coalesce(qt_curso_tec_nm, 0)) as qt_curso_tec_nm,
        sum(coalesce(qt_mat_curso_tec_nm, 0)) as qt_mat_curso_tec_nm,
        sum(coalesce(qt_curso_tec_conc, 0)) as qt_curso_tec_conc,
        sum(coalesce(qt_mat_curso_tec_conc, 0)) as qt_mat_curso_tec_conc,
        sum(coalesce(qt_curso_tec_subs, 0)) as qt_curso_tec_subs,
        sum(coalesce(qt_mat_curso_tec_subs, 0)) as qt_mat_curso_tec_subs,
        sum(coalesce(qt_curso_tec_eja, 0)) as qt_curso_tec_eja,
        sum(coalesce(qt_mat_curso_tec_eja, 0)) as qt_mat_curso_tec_eja,
        sum(coalesce(qt_curso_tec_iftp, 0)) as qt_curso_tec_iftp,
        sum(coalesce(qt_mat_curso_tec_iftp, 0)) as qt_mat_curso_tec_iftp,
        sum(coalesce(qt_curso_tec_iftp_ct, 0)) as qt_curso_tec_iftp_ct,
        sum(coalesce(qt_mat_curso_tec_iftp_ct, 0)) as qt_mat_curso_tec_iftp_ct
    from {{ ref('int_censo_curso_tecnico_escola_ano_2023_2025') }}
    group by ano, id_municipio
)

select
    painel_base.ano,
    painel_base.id_municipio,
    coalesce(tecnico.sg_uf, painel_base.sg_uf) as sg_uf,
    coalesce(tecnico.no_uf, painel_base.no_uf) as no_uf,
    coalesce(tecnico.no_municipio, painel_base.no_municipio) as no_municipio,
    painel_base.periodo_nem,
    painel_base.qt_escolas,
    painel_base.qt_escolas_em,
    case when painel_base.ano >= 2023 then 1 else 0 end as tem_historico_tecnico_no_ano,
    coalesce(tecnico.qt_escolas_com_curso_tecnico, 0) as qt_escolas_com_curso_tecnico,
    coalesce(tecnico.qt_cursos_tecnicos_distintos, 0) as qt_cursos_tecnicos_distintos,
    coalesce(tecnico.qt_areas_tecnicas_distintas, 0) as qt_areas_tecnicas_distintas,
    coalesce(tecnico.qt_curso_tec, 0) as qt_curso_tec,
    coalesce(tecnico.qt_mat_curso_tec, 0) as qt_mat_curso_tec,
    coalesce(tecnico.qt_curso_tec_ct, 0) as qt_curso_tec_ct,
    coalesce(tecnico.qt_mat_curso_tec_ct, 0) as qt_mat_curso_tec_ct,
    coalesce(tecnico.qt_curso_tec_nm, 0) as qt_curso_tec_nm,
    coalesce(tecnico.qt_mat_curso_tec_nm, 0) as qt_mat_curso_tec_nm,
    coalesce(tecnico.qt_curso_tec_conc, 0) as qt_curso_tec_conc,
    coalesce(tecnico.qt_mat_curso_tec_conc, 0) as qt_mat_curso_tec_conc,
    coalesce(tecnico.qt_curso_tec_subs, 0) as qt_curso_tec_subs,
    coalesce(tecnico.qt_mat_curso_tec_subs, 0) as qt_mat_curso_tec_subs,
    coalesce(tecnico.qt_curso_tec_eja, 0) as qt_curso_tec_eja,
    coalesce(tecnico.qt_mat_curso_tec_eja, 0) as qt_mat_curso_tec_eja,
    coalesce(tecnico.qt_curso_tec_iftp, 0) as qt_curso_tec_iftp,
    coalesce(tecnico.qt_mat_curso_tec_iftp, 0) as qt_mat_curso_tec_iftp,
    coalesce(tecnico.qt_curso_tec_iftp_ct, 0) as qt_curso_tec_iftp_ct,
    coalesce(tecnico.qt_mat_curso_tec_iftp_ct, 0) as qt_mat_curso_tec_iftp_ct,
    case when painel_base.qt_escolas > 0 then coalesce(tecnico.qt_escolas_com_curso_tecnico, 0) * 1.0 / painel_base.qt_escolas else null end as prop_escolas_com_curso_tecnico,
    case when painel_base.qt_escolas_em > 0 then coalesce(tecnico.qt_escolas_com_curso_tecnico, 0) * 1.0 / painel_base.qt_escolas_em else null end as prop_escolas_em_com_curso_tecnico
from painel_base
left join tecnico
    on painel_base.ano = tecnico.ano
   and painel_base.id_municipio = tecnico.id_municipio
