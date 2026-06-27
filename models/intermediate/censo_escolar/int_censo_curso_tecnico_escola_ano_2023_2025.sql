select
    ano,
    co_uf,
    sg_uf,
    no_uf,
    id_municipio,
    no_municipio,
    tp_dependencia,
    tp_localizacao,
    id_escola,
    no_entidade,
    case
        when ano between 2019 and 2021 then 'pre_nem'
        when ano between 2022 and 2023 then 'implementacao_nem'
        when ano between 2024 and 2025 then 'pos_nem'
    end as periodo_nem,
    count(distinct co_curso_educ_profissional) as qt_cursos_tecnicos_distintos,
    count(distinct id_area_curso_profissional) as qt_areas_tecnicas_distintas,
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
    sum(coalesce(qt_mat_curso_tec_iftp_ct, 0)) as qt_mat_curso_tec_iftp_ct,
    case
        when sum(coalesce(qt_curso_tec, 0)) > 0 or sum(coalesce(qt_mat_curso_tec, 0)) > 0 then 1
        else 0
    end as in_oferta_curso_tecnico,
    case
        when sum(coalesce(qt_curso_tec_nm, 0)) > 0
          or sum(coalesce(qt_curso_tec_iftp, 0)) > 0
          or sum(coalesce(qt_curso_tec_iftp_ct, 0)) > 0
        then 1
        else 0
    end as in_oferta_curso_tecnico_nem
from {{ ref('stg_censo_escolar_curso_tecnico_2023_2025') }}
where id_municipio is not null
  and id_escola is not null
group by
    ano,
    co_uf,
    sg_uf,
    no_uf,
    id_municipio,
    no_municipio,
    tp_dependencia,
    tp_localizacao,
    id_escola,
    no_entidade
