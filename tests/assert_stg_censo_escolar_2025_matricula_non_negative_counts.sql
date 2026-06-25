select *
from {{ ref('stg_censo_escolar_2025_matricula') }}
where
    coalesce(qt_mat_med, 0) < 0
    or coalesce(qt_mat_med_prop, 0) < 0
    or coalesce(qt_mat_med_iftp_ct, 0) < 0
    or coalesce(qt_mat_med_iftp_qp, 0) < 0
    or coalesce(qt_mat_med_nm, 0) < 0
    or coalesce(qt_mat_med_ifa, 0) < 0
    or coalesce(qt_mat_prof, 0) < 0
    or coalesce(qt_mat_prof_tec, 0) < 0
    or coalesce(qt_mat_med_int, 0) < 0
    or coalesce(qt_mat_prof_int, 0) < 0
    or coalesce(qt_mat_prof_tec_int, 0) < 0
