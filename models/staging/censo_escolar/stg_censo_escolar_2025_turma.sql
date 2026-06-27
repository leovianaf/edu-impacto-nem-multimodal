with turma as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
        cast("CO_ENTIDADE" as varchar) as id_escola,
        try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
        try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
        try_cast("QT_TUR_MED" as integer) as qt_tur_med,
        try_cast("QT_TUR_MED_PROP" as integer) as qt_tur_med_prop,
        try_cast("QT_TUR_MED_IFTP_CT" as integer) as qt_tur_med_iftp_ct,
        try_cast("QT_TUR_MED_IFTP_QP" as integer) as qt_tur_med_iftp_qp,
        try_cast("QT_TUR_MED_NM" as integer) as qt_tur_med_nm,
        try_cast("QT_TUR_MED_IFA" as integer) as qt_tur_med_ifa,
        try_cast("QT_TUR_MED_IFA_LING" as integer) as qt_tur_med_ifa_ling,
        try_cast("QT_TUR_MED_IFA_MATE" as integer) as qt_tur_med_ifa_mate,
        try_cast("QT_TUR_MED_IFA_CIENC" as integer) as qt_tur_med_ifa_cienc,
        try_cast("QT_TUR_MED_IFA_HUMA" as integer) as qt_tur_med_ifa_huma,
        try_cast("QT_TUR_MED_INT" as integer) as qt_tur_med_int,
        try_cast("QT_TUR_MED_EAD" as integer) as qt_tur_med_ead,
        try_cast("QT_TUR_PROF" as integer) as qt_tur_prof,
        try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec,
        try_cast("QT_TUR_PROF_TEC_IFTP_CT" as integer) as qt_tur_prof_tec_iftp_ct,
        try_cast("QT_TUR_PROF_IFTP_QP" as integer) as qt_tur_prof_iftp_qp,
        try_cast("QT_TUR_PROF_TEC_INT" as integer) as qt_tur_prof_tec_int,
        try_cast("QT_TUR_EJA_MED" as integer) as qt_tur_eja_med,
        try_cast("QT_TUR_EJA_MED_TEC" as integer) as qt_tur_eja_med_tec
    from read_csv(
        'data/raw/censo_escolar_2025/Tabela_Turma_2025.csv.gz',
        delim=';',
        header=true,
        all_varchar=true,
        ignore_errors=true
    )
)

select
    turma.ano,
    escola.co_uf,
    escola.sg_uf,
    escola.id_municipio,
    escola.id_escola,
    escola.tp_dependencia,
    escola.tp_localizacao,
    turma.qt_tur_bas,
    turma.qt_tur_fund,
    turma.qt_tur_med,
    turma.qt_tur_med_prop,
    turma.qt_tur_med_iftp_ct,
    turma.qt_tur_med_iftp_qp,
    turma.qt_tur_med_nm,
    turma.qt_tur_med_ifa,
    turma.qt_tur_med_ifa_ling,
    turma.qt_tur_med_ifa_mate,
    turma.qt_tur_med_ifa_cienc,
    turma.qt_tur_med_ifa_huma,
    turma.qt_tur_med_int,
    turma.qt_tur_med_ead,
    turma.qt_tur_prof,
    turma.qt_tur_prof_tec,
    turma.qt_tur_prof_tec_iftp_ct,
    turma.qt_tur_prof_iftp_qp,
    turma.qt_tur_prof_tec_int,
    turma.qt_tur_eja_med,
    turma.qt_tur_eja_med_tec
from turma
left join {{ ref('stg_censo_escolar_2025_escola') }} as escola
    on turma.ano = escola.ano
   and turma.id_escola = escola.id_escola
