select *
from {{ ref('stg_censo_escolar_2025_curso_tecnico') }}
where
    coalesce(qt_curso_tec, 0) < 0
    or coalesce(qt_mat_curso_tec, 0) < 0
    or coalesce(qt_curso_tec_iftp, 0) < 0
    or coalesce(qt_mat_curso_tec_iftp, 0) < 0
    or coalesce(qt_curso_tec_nm, 0) < 0
    or coalesce(qt_mat_curso_tec_nm, 0) < 0
    or coalesce(qt_curso_tec_conc, 0) < 0
    or coalesce(qt_mat_curso_tec_conc, 0) < 0
    or coalesce(qt_curso_tec_subs, 0) < 0
    or coalesce(qt_mat_curso_tec_subs, 0) < 0
    or coalesce(qt_curso_tec_iftp_ct, 0) < 0
    or coalesce(qt_mat_curso_tec_iftp_ct, 0) < 0
    or coalesce(qt_curso_tec_eja, 0) < 0
    or coalesce(qt_mat_curso_tec_eja, 0) < 0
