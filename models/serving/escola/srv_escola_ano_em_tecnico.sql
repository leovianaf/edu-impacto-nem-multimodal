{{ config(materialized='table') }}

with em as (
    select *
    from {{ ref('srv_escola_ano_em') }}
),
tecnico as (
    select
        ano,
        id_escola,
        id_municipio,
        qt_cursos_tecnicos_distintos,
        qt_areas_tecnicas_distintas,
        qt_curso_tec,
        qt_mat_curso_tec,
        qt_curso_tec_nm,
        qt_mat_curso_tec_nm,
        qt_curso_tec_iftp,
        qt_mat_curso_tec_iftp,
        in_oferta_curso_tecnico,
        in_oferta_curso_tecnico_nem
    from {{ ref('srv_escola_ano_tecnico') }}
)

select
    em.ano,
    em.id_municipio,
    em.nome_municipio,
    em.id_uf,
    em.sigla_uf,
    em.nome_uf,
    em.nome_regiao,
    em.capital_uf,
    em.amazonia_legal,
    em.no_entidade,
    em.id_escola,
    em.tp_dependencia,
    em.tp_localizacao,
    em.fonte_censo,
    em.periodo_nem,
    em.ordem_periodo_nem,
    em.in_med,
    em.in_med_padronizado,
    em.in_prof_tec,
    em.in_itinerario_aprofundamento,
    em.in_itinerario_tecn_prof,
    em.in_profissionalizante,
    em.in_biblioteca,
    em.in_internet,
    em.in_internet_aprendizagem,
    em.in_laboratorio_ciencias,
    em.in_laboratorio_informatica,
    em.in_laboratorio_educ_prof,
    em.in_sala_oficinas_educ_prof,
    em.in_quadra_esportes,
    em.qt_mat_med_compat,
    em.qt_mat_med_int_compat,
    em.qt_mat_med_prop,
    em.qt_mat_med_nm,
    em.qt_mat_med_ifa,
    em.qt_mat_med_iftp_ct,
    em.qt_mat_med_iftp_qp,
    em.qt_mat_med_arti_iftp_ct,
    em.qt_mat_med_arti_iftp_qp,
    em.qt_mat_prof_tec_compat,
    em.qt_mat_prof_tec,
    em.qt_tur_med_compat,
    em.qt_tur_med_int_compat,
    em.qt_tur_med_prop,
    em.qt_tur_med_nm,
    em.qt_tur_med_ifa,
    em.qt_tur_med_iftp_ct,
    em.qt_tur_med_iftp_qp,
    em.qt_doc_med_compat,
    em.qt_doc_med,
    em.qt_doc_prof_tec,
    em.qt_gest_bas,
    em.qt_gest_bas_espec_ens_medio,
    em.prop_mat_em_integral_escola,
    em.prop_mat_em_tecnico_profissional_escola,
    em.prop_tur_em_integral_escola,
    em.prop_doc_em_prof_tec_escola,
    tecnico.qt_cursos_tecnicos_distintos,
    tecnico.qt_areas_tecnicas_distintas,
    tecnico.qt_curso_tec,
    tecnico.qt_mat_curso_tec,
    tecnico.qt_curso_tec_nm,
    tecnico.qt_mat_curso_tec_nm,
    tecnico.qt_curso_tec_iftp,
    tecnico.qt_mat_curso_tec_iftp,
    tecnico.in_oferta_curso_tecnico,
    tecnico.in_oferta_curso_tecnico_nem,
    em.ano_saeb_referencia,
    em.tem_saeb_no_ano_flag,
    em.pib,
    em.tem_pib_no_ano,
    em.populacao,
    em.taxa_alfabetizacao,
    em.taxa_alfabetizacao_detalhada_calculada,
    em.media_12_lp,
    em.media_12_mt,
    em.media_12_lp_mt,
    case
        when coalesce(em.in_med_padronizado, 0) = 1 and coalesce(tecnico.in_oferta_curso_tecnico, 0) = 1 then 1
        else 0
    end as tem_em_e_tecnico_no_mesmo_ano,
    case
        when coalesce(em.in_med_padronizado, 0) = 1 and coalesce(tecnico.in_oferta_curso_tecnico_nem, 0) = 1 then 1
        else 0
    end as tem_em_e_tecnico_no_nem
from em
left join tecnico
    on em.ano = tecnico.ano
   and em.id_escola = tecnico.id_escola
   and em.id_municipio = tecnico.id_municipio
