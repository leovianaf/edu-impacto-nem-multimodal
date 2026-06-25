select *
from {{ ref('stg_censo_escolar_escolas_2019_2024') }}
where
    coalesce(qt_mat_med, 0) < 0
    or coalesce(qt_mat_med_prop, 0) < 0
    or coalesce(qt_mat_med_ct, 0) < 0
    or coalesce(qt_mat_med_nm, 0) < 0
    or coalesce(qt_mat_med_int, 0) < 0
    or coalesce(qt_mat_prof, 0) < 0
    or coalesce(qt_mat_prof_tec, 0) < 0
    or coalesce(qt_doc_med, 0) < 0
    or coalesce(qt_doc_prof_tec, 0) < 0
    or coalesce(qt_tur_med, 0) < 0
    or coalesce(qt_tur_prof_tec, 0) < 0
    or coalesce(qt_tur_med_int, 0) < 0
