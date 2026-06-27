with curso_2023 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
        cast("CO_UF" as varchar) as co_uf,
        cast("SG_UF" as varchar) as sg_uf,
        cast("NO_UF" as varchar) as no_uf,
        cast("CO_MUNICIPIO" as varchar) as id_municipio,
        cast("NO_MUNICIPIO" as varchar) as no_municipio,
        try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
        try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
        cast("CO_ENTIDADE" as varchar) as id_escola,
        cast("NO_ENTIDADE" as varchar) as no_entidade,
        cast("ID_AREA_CURSO_PROFISSIONAL" as varchar) as id_area_curso_profissional,
        cast("NO_AREA_CURSO_PROFISSIONAL" as varchar) as no_area_curso_profissional,
        cast("CO_CURSO_EDUC_PROFISSIONAL" as varchar) as co_curso_educ_profissional,
        cast("NO_CURSO_EDUC_PROFISSIONAL" as varchar) as no_curso_educ_profissional,
        try_cast("QT_CURSO_TEC" as integer) as qt_curso_tec,
        try_cast("QT_MAT_CURSO_TEC" as integer) as qt_mat_curso_tec,
        try_cast("QT_CURSO_TEC_CT" as integer) as qt_curso_tec_ct,
        try_cast("QT_MAT_CURSO_TEC_CT" as integer) as qt_mat_curso_tec_ct,
        try_cast("QT_CURSO_TEC_NM" as integer) as qt_curso_tec_nm,
        try_cast("QT_MAT_CURSO_TEC_NM" as integer) as qt_mat_curso_tec_nm,
        try_cast("QT_CURSO_TEC_CONC" as integer) as qt_curso_tec_conc,
        try_cast("QT_MAT_CURSO_TEC_CONC" as integer) as qt_mat_curso_tec_conc,
        try_cast("QT_CURSO_TEC_SUBS" as integer) as qt_curso_tec_subs,
        try_cast("QT_MAT_TEC_SUBS" as integer) as qt_mat_curso_tec_subs,
        try_cast("QT_CURSO_TEC_EJA" as integer) as qt_curso_tec_eja,
        try_cast("QT_MAT_TEC_EJA" as integer) as qt_mat_curso_tec_eja,
        null::integer as qt_curso_tec_iftp,
        null::integer as qt_mat_curso_tec_iftp,
        null::integer as qt_curso_tec_iftp_ct,
        null::integer as qt_mat_curso_tec_iftp_ct
    from read_csv(
        'data/raw/censo_escolar_2023/suplemento_cursos_tecnicos_2023.csv.gz',
        delim=';',
        header=true,
        all_varchar=true,
        ignore_errors=true
    )
),

curso_2024 as (
    select
        try_cast("NU_ANO_CENSO" as integer) as ano,
        cast("CO_UF" as varchar) as co_uf,
        cast("SG_UF" as varchar) as sg_uf,
        cast("NO_UF" as varchar) as no_uf,
        cast("CO_MUNICIPIO" as varchar) as id_municipio,
        cast("NO_MUNICIPIO" as varchar) as no_municipio,
        try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
        try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
        cast("CO_ENTIDADE" as varchar) as id_escola,
        cast("NO_ENTIDADE" as varchar) as no_entidade,
        cast("ID_AREA_CURSO_PROFISSIONAL" as varchar) as id_area_curso_profissional,
        cast("NO_AREA_CURSO_PROFISSIONAL" as varchar) as no_area_curso_profissional,
        cast("CO_CURSO_EDUC_PROFISSIONAL" as varchar) as co_curso_educ_profissional,
        cast("NO_CURSO_EDUC_PROFISSIONAL" as varchar) as no_curso_educ_profissional,
        try_cast("QT_CURSO_TEC" as integer) as qt_curso_tec,
        try_cast("QT_MAT_CURSO_TEC" as integer) as qt_mat_curso_tec,
        try_cast("QT_CURSO_TEC_CT" as integer) as qt_curso_tec_ct,
        try_cast("QT_MAT_CURSO_TEC_CT" as integer) as qt_mat_curso_tec_ct,
        try_cast("QT_CURSO_TEC_NM" as integer) as qt_curso_tec_nm,
        try_cast("QT_MAT_CURSO_TEC_NM" as integer) as qt_mat_curso_tec_nm,
        try_cast("QT_CURSO_TEC_CONC" as integer) as qt_curso_tec_conc,
        try_cast("QT_MAT_CURSO_TEC_CONC" as integer) as qt_mat_curso_tec_conc,
        try_cast("QT_CURSO_TEC_SUBS" as integer) as qt_curso_tec_subs,
        try_cast("QT_MAT_TEC_SUBS" as integer) as qt_mat_curso_tec_subs,
        try_cast("QT_CURSO_TEC_EJA" as integer) as qt_curso_tec_eja,
        try_cast("QT_MAT_TEC_EJA" as integer) as qt_mat_curso_tec_eja,
        null::integer as qt_curso_tec_iftp,
        null::integer as qt_mat_curso_tec_iftp,
        null::integer as qt_curso_tec_iftp_ct,
        null::integer as qt_mat_curso_tec_iftp_ct
    from read_csv(
        'data/raw/censo_escolar_2024/suplemento_cursos_tecnicos_2024.csv.gz',
        delim=';',
        header=true,
        all_varchar=true,
        ignore_errors=true
    )
),

curso_2025 as (
    select
        curso.ano,
        curso.co_uf,
        curso.sg_uf,
        null::varchar as no_uf,
        curso.id_municipio,
        escola.no_municipio,
        curso.tp_dependencia,
        curso.tp_localizacao,
        curso.id_escola,
        curso.no_entidade,
        curso.id_area_curso_profissional,
        curso.no_area_curso_profissional,
        curso.co_curso_educ_profissional,
        curso.no_curso_educ_profissional,
        curso.qt_curso_tec,
        curso.qt_mat_curso_tec,
        null::integer as qt_curso_tec_ct,
        null::integer as qt_mat_curso_tec_ct,
        curso.qt_curso_tec_nm,
        curso.qt_mat_curso_tec_nm,
        curso.qt_curso_tec_conc,
        curso.qt_mat_curso_tec_conc,
        curso.qt_curso_tec_subs,
        curso.qt_mat_curso_tec_subs,
        curso.qt_curso_tec_eja,
        curso.qt_mat_curso_tec_eja,
        curso.qt_curso_tec_iftp,
        curso.qt_mat_curso_tec_iftp,
        curso.qt_curso_tec_iftp_ct,
        curso.qt_mat_curso_tec_iftp_ct
    from {{ ref('stg_censo_escolar_2025_curso_tecnico') }} as curso
    left join {{ ref('stg_censo_escolar_2025_escola') }} as escola
        on curso.ano = escola.ano
       and curso.id_escola = escola.id_escola
)

select * from curso_2023
union all
select * from curso_2024
union all
select * from curso_2025
