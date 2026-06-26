select
    try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("ID_AREA_CURSO_PROFISSIONAL" as varchar) as id_area_curso_profissional,
    cast("NO_AREA_CURSO_PROFISSIONAL" as varchar) as no_area_curso_profissional,
    cast("CO_CURSO_EDUC_PROFISSIONAL" as varchar) as co_curso_educ_profissional,
    cast("NO_CURSO_EDUC_PROFISSIONAL" as varchar) as no_curso_educ_profissional,
    try_cast("QT_CURSO_TEC" as integer) as qt_curso_tec,
    try_cast("QT_MAT_CURSO_TEC" as integer) as qt_mat_curso_tec,
    try_cast("QT_CURSO_TEC_IFTP" as integer) as qt_curso_tec_iftp,
    try_cast("QT_MAT_CURSO_TEC_IFTP" as integer) as qt_mat_curso_tec_iftp,
    try_cast("QT_CURSO_TEC_NM" as integer) as qt_curso_tec_nm,
    try_cast("QT_MAT_CURSO_TEC_NM" as integer) as qt_mat_curso_tec_nm,
    try_cast("QT_CURSO_TEC_CONC" as integer) as qt_curso_tec_conc,
    try_cast("QT_MAT_CURSO_TEC_CONC" as integer) as qt_mat_curso_tec_conc,
    try_cast("QT_CURSO_TEC_SUBS" as integer) as qt_curso_tec_subs,
    try_cast("QT_MAT_CURSO_TEC_SUBS" as integer) as qt_mat_curso_tec_subs,
    try_cast("QT_CURSO_TEC_IFTP_CT" as integer) as qt_curso_tec_iftp_ct,
    try_cast("QT_MAT_CURSO_TEC_IFTP_CT" as integer) as qt_mat_curso_tec_iftp_ct,
    try_cast("QT_CURSO_TEC_EJA" as integer) as qt_curso_tec_eja,
    try_cast("QT_MAT_CURSO_TEC_EJA" as integer) as qt_mat_curso_tec_eja
from read_csv(
    'data/raw/censo_escolar_2025/Tabela_Curso_Tecnico_2025.csv.gz',
    delim=';',
    header=true,
    all_varchar=true,
    ignore_errors=true
)
