with escola as (
    select
        ano,
        id_municipio,
        sum(coalesce(qt_mat_med_compat, 0)) as qt_mat_med_escola,
        sum(coalesce(qt_tur_med_compat, 0)) as qt_tur_med_escola,
        sum(coalesce(qt_doc_med_compat, 0)) as qt_doc_med_escola,
        sum(coalesce(qt_mat_prof_tec_compat, 0)) as qt_mat_prof_tec_escola
    from {{ ref('int_censo_escola_ano_2019_2025') }}
    group by ano, id_municipio
)
select
    e.ano,
    e.id_municipio,
    e.qt_mat_med_escola,
    m.qt_mat_med,
    e.qt_tur_med_escola,
    m.qt_tur_med,
    e.qt_doc_med_escola,
    m.qt_doc_med,
    e.qt_mat_prof_tec_escola,
    m.qt_mat_prof_tec
from escola e
inner join {{ ref('int_municipio_ano_oferta_educacional') }} m
    on e.ano = m.ano
   and e.id_municipio = m.id_municipio
where e.qt_mat_med_escola != m.qt_mat_med
   or e.qt_tur_med_escola != m.qt_tur_med
   or e.qt_doc_med_escola != m.qt_doc_med
   or e.qt_mat_prof_tec_escola != m.qt_mat_prof_tec
