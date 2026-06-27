select *
from {{ ref('stg_censo_escolar_2025_gestor') }}
where
    coalesce(qt_gest_bas, 0) < 0
    or coalesce(qt_gest_bas_fem, 0) < 0
    or coalesce(qt_gest_bas_masc, 0) < 0
    or coalesce(qt_gest_bas_branca, 0) < 0
    or coalesce(qt_gest_bas_preta, 0) < 0
    or coalesce(qt_gest_bas_parda, 0) < 0
    or coalesce(qt_gest_bas_30_39, 0) < 0
    or coalesce(qt_gest_bas_40_49, 0) < 0
    or coalesce(qt_gest_bas_50_54, 0) < 0
    or coalesce(qt_gest_bas_55_59, 0) < 0
    or coalesce(qt_gest_bas_60_mais, 0) < 0
    or coalesce(qt_gest_bas_pcd, 0) < 0
    or coalesce(qt_gest_bas_esco_em, 0) < 0
    or coalesce(qt_gest_bas_esco_sup_grad_licen, 0) < 0
    or coalesce(qt_gest_bas_esco_sup_pos_espec, 0) < 0
    or coalesce(qt_gest_bas_esco_sup_pos_mestra, 0) < 0
    or coalesce(qt_gest_bas_esco_sup_pos_douto, 0) < 0
    or coalesce(qt_gest_bas_vinculo_concur, 0) < 0
    or coalesce(qt_gest_bas_vinculo_contra, 0) < 0
    or coalesce(qt_gest_bas_vinculo_clt, 0) < 0
    or coalesce(qt_gest_bas_diretor, 0) < 0
    or coalesce(qt_gest_bas_outro, 0) < 0
    or coalesce(qt_gest_bas_acesso_cargo_indic, 0) < 0
    or coalesce(qt_gest_bas_acesso_cargo_sel, 0) < 0
    or coalesce(qt_gest_bas_acesso_cargo_conc, 0) < 0
    or coalesce(qt_gest_bas_acesso_cargo_eleic, 0) < 0
    or coalesce(qt_gest_bas_espec_ens_medio, 0) < 0
    or coalesce(qt_gest_bas_espec_gestao, 0) < 0
