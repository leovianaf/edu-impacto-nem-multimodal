select *
from {{ ref('stg_censo_escolar_2025_docente') }}
where
    coalesce(qt_doc_bas, 0) < 0
    or coalesce(qt_doc_fund, 0) < 0
    or coalesce(qt_doc_med, 0) < 0
    or coalesce(qt_doc_med_prop, 0) < 0
    or coalesce(qt_doc_med_iftp_ct, 0) < 0
    or coalesce(qt_doc_med_iftp_qp, 0) < 0
    or coalesce(qt_doc_med_nm, 0) < 0
    or coalesce(qt_doc_prof, 0) < 0
    or coalesce(qt_doc_prof_tec, 0) < 0
    or coalesce(qt_doc_prof_tec_iftp_ct, 0) < 0
    or coalesce(qt_doc_prof_iftp_qp, 0) < 0
    or coalesce(qt_doc_eja_med, 0) < 0
    or coalesce(qt_doc_eja_med_tec, 0) < 0
    or coalesce(qt_doc_bas_esco_em, 0) < 0
    or coalesce(qt_doc_bas_esco_sup_grad_licen, 0) < 0
    or coalesce(qt_doc_bas_esco_sup_pos_espec, 0) < 0
    or coalesce(qt_doc_bas_esco_sup_pos_mestra, 0) < 0
    or coalesce(qt_doc_bas_esco_sup_pos_douto, 0) < 0
    or coalesce(qt_doc_bas_vinculo_concur, 0) < 0
    or coalesce(qt_doc_bas_vinculo_contra, 0) < 0
    or coalesce(qt_doc_bas_vinculo_clt, 0) < 0
    or coalesce(qt_doc_bas_disc_projeto_de_vida, 0) < 0
    or coalesce(qt_doc_bas_disc_profissiona, 0) < 0
    or coalesce(qt_doc_bas_disc_info_computacao, 0) < 0
