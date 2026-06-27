with docente as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
        cast("CO_ENTIDADE" as varchar) as id_escola,
        try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
        try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
        try_cast("QT_DOC_MED" as integer) as qt_doc_med,
        try_cast("QT_DOC_MED_PROP" as integer) as qt_doc_med_prop,
        try_cast("QT_DOC_MED_IFTP_CT" as integer) as qt_doc_med_iftp_ct,
        try_cast("QT_DOC_MED_IFTP_QP" as integer) as qt_doc_med_iftp_qp,
        try_cast("QT_DOC_MED_NM" as integer) as qt_doc_med_nm,
        try_cast("QT_DOC_PROF" as integer) as qt_doc_prof,
        try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
        try_cast("QT_DOC_PROF_TEC_IFTP_CT" as integer) as qt_doc_prof_tec_iftp_ct,
        try_cast("QT_DOC_PROF_IFTP_QP" as integer) as qt_doc_prof_iftp_qp,
        try_cast("QT_DOC_EJA_MED" as integer) as qt_doc_eja_med,
        try_cast("QT_DOC_EJA_MED_TEC" as integer) as qt_doc_eja_med_tec,
        try_cast("QT_DOC_BAS_ESCO_EM" as integer) as qt_doc_bas_esco_em,
        try_cast("QT_DOC_BAS_ESCO_SUP_GRAD_LICEN" as integer) as qt_doc_bas_esco_sup_grad_licen,
        try_cast("QT_DOC_BAS_ESCO_SUP_POS_ESPEC" as integer) as qt_doc_bas_esco_sup_pos_espec,
        try_cast("QT_DOC_BAS_ESCO_SUP_POS_MESTRA" as integer) as qt_doc_bas_esco_sup_pos_mestra,
        try_cast("QT_DOC_BAS_ESCO_SUP_POS_DOUTO" as integer) as qt_doc_bas_esco_sup_pos_douto,
        try_cast("QT_DOC_BAS_VINCULO_CONCUR" as integer) as qt_doc_bas_vinculo_concur,
        try_cast("QT_DOC_BAS_VINCULO_CONTRA" as integer) as qt_doc_bas_vinculo_contra,
        try_cast("QT_DOC_BAS_VINCULO_CLT" as integer) as qt_doc_bas_vinculo_clt,
        try_cast("QT_DOC_BAS_DISC_PROJETO_DE_VIDA" as integer) as qt_doc_bas_disc_projeto_de_vida,
        try_cast("QT_DOC_BAS_DISC_PROFISSIONA" as integer) as qt_doc_bas_disc_profissiona,
        try_cast("QT_DOC_BAS_DISC_INFO_COMPUTACAO" as integer) as qt_doc_bas_disc_info_computacao
    from read_csv(
        'data/raw/censo_escolar_2025/Tabela_Docente_2025.csv.gz',
        delim=';',
        header=true,
        all_varchar=true,
        ignore_errors=true
    )
)

select
    docente.ano,
    escola.co_uf,
    escola.sg_uf,
    escola.id_municipio,
    escola.id_escola,
    escola.tp_dependencia,
    escola.tp_localizacao,
    docente.qt_doc_bas,
    docente.qt_doc_fund,
    docente.qt_doc_med,
    docente.qt_doc_med_prop,
    docente.qt_doc_med_iftp_ct,
    docente.qt_doc_med_iftp_qp,
    docente.qt_doc_med_nm,
    docente.qt_doc_prof,
    docente.qt_doc_prof_tec,
    docente.qt_doc_prof_tec_iftp_ct,
    docente.qt_doc_prof_iftp_qp,
    docente.qt_doc_eja_med,
    docente.qt_doc_eja_med_tec,
    docente.qt_doc_bas_esco_em,
    docente.qt_doc_bas_esco_sup_grad_licen,
    docente.qt_doc_bas_esco_sup_pos_espec,
    docente.qt_doc_bas_esco_sup_pos_mestra,
    docente.qt_doc_bas_esco_sup_pos_douto,
    docente.qt_doc_bas_vinculo_concur,
    docente.qt_doc_bas_vinculo_contra,
    docente.qt_doc_bas_vinculo_clt,
    docente.qt_doc_bas_disc_projeto_de_vida,
    docente.qt_doc_bas_disc_profissiona,
    docente.qt_doc_bas_disc_info_computacao
from docente
left join {{ ref('stg_censo_escolar_2025_escola') }} as escola
    on docente.ano = escola.ano
   and docente.id_escola = escola.id_escola
