with censo_2019 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    null::integer as qt_mat_med_prop,
    null::integer as qt_mat_med_ct,
    null::integer as qt_mat_med_nm,
    null::integer as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2019/microdados_ed_basica_2019.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
),

censo_2020 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    null::integer as qt_mat_med_prop,
    null::integer as qt_mat_med_ct,
    null::integer as qt_mat_med_nm,
    null::integer as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2020/microdados_ed_basica_2020.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
),

censo_2021 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    null::integer as qt_mat_med_prop,
    null::integer as qt_mat_med_ct,
    null::integer as qt_mat_med_nm,
    null::integer as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2021/microdados_ed_basica_2021.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
),

censo_2022 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    null::integer as qt_mat_med_prop,
    null::integer as qt_mat_med_ct,
    null::integer as qt_mat_med_nm,
    null::integer as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2022/microdados_ed_basica_2022.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
),

censo_2023 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    try_cast("QT_MAT_MED_PROP" as integer) as qt_mat_med_prop,
    try_cast("QT_MAT_MED_CT" as integer) as qt_mat_med_ct,
    try_cast("QT_MAT_MED_NM" as integer) as qt_mat_med_nm,
    try_cast("QT_TUR_MED_INT" as integer) as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2023/microdados_ed_basica_2023.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
),

censo_2024 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_MEDIACAO_PRESENCIAL" as integer) as in_mediacao_presencial,
    try_cast("IN_MEDIACAO_SEMIPRESENCIAL" as integer) as in_mediacao_semipresencial,
    try_cast("IN_MEDIACAO_EAD" as integer) as in_mediacao_ead,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_INF" as integer) as in_inf,
    try_cast("IN_FUND" as integer) as in_fund,
    case
        when coalesce(try_cast("IN_INF" as integer), 0) = 1
          or coalesce(try_cast("IN_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_MED" as integer), 0) = 1
          or coalesce(try_cast("IN_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_EJA" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
    try_cast("IN_MED" as integer) as in_med,
    try_cast("IN_PROF" as integer) as in_prof,
    try_cast("IN_PROF_TEC" as integer) as in_prof_tec,
    try_cast("IN_EJA" as integer) as in_eja,
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("QT_MAT_BAS" as integer) as qt_mat_bas,
    try_cast("QT_MAT_INF" as integer) as qt_mat_inf,
    try_cast("QT_MAT_FUND" as integer) as qt_mat_fund,
    try_cast("QT_MAT_MED" as integer) as qt_mat_med,
    try_cast("QT_MAT_MED_PROP" as integer) as qt_mat_med_prop,
    try_cast("QT_MAT_MED_CT" as integer) as qt_mat_med_ct,
    try_cast("QT_MAT_MED_NM" as integer) as qt_mat_med_nm,
    try_cast("QT_TUR_MED_INT" as integer) as qt_tur_med_int,
    try_cast("QT_MAT_MED_INT" as integer) as qt_mat_med_int,
    try_cast("QT_MAT_PROF" as integer) as qt_mat_prof,
    try_cast("QT_MAT_PROF_TEC" as integer) as qt_mat_prof_tec,
    try_cast("QT_DOC_BAS" as integer) as qt_doc_bas,
    try_cast("QT_DOC_FUND" as integer) as qt_doc_fund,
    try_cast("QT_DOC_MED" as integer) as qt_doc_med,
    try_cast("QT_DOC_PROF_TEC" as integer) as qt_doc_prof_tec,
    try_cast("QT_TUR_BAS" as integer) as qt_tur_bas,
    try_cast("QT_TUR_FUND" as integer) as qt_tur_fund,
    try_cast("QT_TUR_MED" as integer) as qt_tur_med,
    try_cast("QT_TUR_PROF_TEC" as integer) as qt_tur_prof_tec
    from read_csv('data/raw/censo_escolar_2024/microdados_ed_basica_2024.csv.gz', delim=';', header=true, all_varchar=true, ignore_errors=true)
)

select * from censo_2019
union all
select * from censo_2020
union all
select * from censo_2021
union all
select * from censo_2022
union all
select * from censo_2023
union all
select * from censo_2024
