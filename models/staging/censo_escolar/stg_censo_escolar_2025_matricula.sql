select
    try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    try_cast("QT_MAT_MED_PROP" as integer) as qt_mat_med_prop,
    try_cast("QT_MAT_MED_IFTP_CT" as integer) as qt_mat_med_iftp_ct,
    try_cast("QT_MAT_MED_IFTP_QP" as integer) as qt_mat_med_iftp_qp,
    try_cast("QT_MAT_MED_NM" as integer) as qt_mat_med_nm,
    try_cast("QT_MAT_MED_IFA" as integer) as qt_mat_med_ifa,
    try_cast("QT_MAT_MED_IFA_LING" as integer) as qt_mat_med_ifa_ling,
    try_cast("QT_MAT_MED_IFA_MATE" as integer) as qt_mat_med_ifa_mate,
    try_cast("QT_MAT_MED_IFA_CIENC" as integer) as qt_mat_med_ifa_cienc,
    try_cast("QT_MAT_MED_IFA_HUMA" as integer) as qt_mat_med_ifa_huma,
    try_cast("QT_MAT_MED_ARTI_IFTP_CT" as integer) as qt_mat_med_arti_iftp_ct,
    try_cast("QT_MAT_MED_ARTI_IFTP_QP" as integer) as qt_mat_med_arti_iftp_qp,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_MAT_PROF_TEC_IFTP_CT" as integer) as qt_mat_prof_tec_iftp_ct,
    try_cast("QT_MAT_PROF_IFTP_QP" as integer) as qt_mat_prof_iftp_qp,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF_INT" as integer) as qt_mat_prof_int,
    try_cast("QT_MAT_PROF_TEC_INT" as integer) as qt_mat_prof_tec_int
from read_csv(
    'data/raw/censo_escolar_2025/Tabela_Matricula_2025.csv.gz',
    delim=';',
    header=true,
    all_varchar=true,
    ignore_errors=true
)
