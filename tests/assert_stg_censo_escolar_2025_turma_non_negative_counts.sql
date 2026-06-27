select *
from {{ ref('stg_censo_escolar_2025_turma') }}
where
    coalesce(qt_tur_bas, 0) < 0
    or coalesce(qt_tur_fund, 0) < 0
    or coalesce(qt_tur_med, 0) < 0
    or coalesce(qt_tur_med_prop, 0) < 0
    or coalesce(qt_tur_med_iftp_ct, 0) < 0
    or coalesce(qt_tur_med_iftp_qp, 0) < 0
    or coalesce(qt_tur_med_nm, 0) < 0
    or coalesce(qt_tur_med_ifa, 0) < 0
    or coalesce(qt_tur_med_ifa_ling, 0) < 0
    or coalesce(qt_tur_med_ifa_mate, 0) < 0
    or coalesce(qt_tur_med_ifa_cienc, 0) < 0
    or coalesce(qt_tur_med_ifa_huma, 0) < 0
    or coalesce(qt_tur_med_int, 0) < 0
    or coalesce(qt_tur_med_ead, 0) < 0
    or coalesce(qt_tur_prof, 0) < 0
    or coalesce(qt_tur_prof_tec, 0) < 0
    or coalesce(qt_tur_prof_tec_iftp_ct, 0) < 0
    or coalesce(qt_tur_prof_iftp_qp, 0) < 0
    or coalesce(qt_tur_prof_tec_int, 0) < 0
    or coalesce(qt_tur_eja_med, 0) < 0
    or coalesce(qt_tur_eja_med_tec, 0) < 0
