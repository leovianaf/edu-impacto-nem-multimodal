with saeb_canonico as (
    select
        ano_saeb as ano,
        id_municipio,
        co_uf,
        no_uf,
        no_municipio,
        dependencia_adm,
        localizacao,
        media_5_lp,
        media_5_mt,
        media_9_lp,
        media_9_mt,
        media_12_lp,
        media_12_mt,
        nivel_0_lp12,
        nivel_1_lp12,
        nivel_2_lp12,
        nivel_3_lp12,
        nivel_4_lp12,
        nivel_5_lp12,
        nivel_6_lp12,
        nivel_7_lp12,
        nivel_8_lp12,
        nivel_0_mt12,
        nivel_1_mt12,
        nivel_2_mt12,
        nivel_3_mt12,
        nivel_4_mt12,
        nivel_5_mt12,
        nivel_6_mt12,
        nivel_7_mt12,
        nivel_8_mt12,
        nivel_9_mt12,
        nivel_10_mt12,
        nivel_0_lp13,
        nivel_1_lp13,
        nivel_2_lp13,
        nivel_3_lp13,
        nivel_4_lp13,
        nivel_5_lp13,
        nivel_6_lp13,
        nivel_7_lp13,
        nivel_8_lp13,
        nivel_0_mt13,
        nivel_1_mt13,
        nivel_2_mt13,
        nivel_3_mt13,
        nivel_4_mt13,
        nivel_5_mt13,
        nivel_6_mt13,
        nivel_7_mt13,
        nivel_8_mt13,
        nivel_9_mt13,
        nivel_10_mt13,
        nivel_0_lp14,
        nivel_1_lp14,
        nivel_2_lp14,
        nivel_3_lp14,
        nivel_4_lp14,
        nivel_5_lp14,
        nivel_6_lp14,
        nivel_7_lp14,
        nivel_8_lp14,
        nivel_0_mt14,
        nivel_1_mt14,
        nivel_2_mt14,
        nivel_3_mt14,
        nivel_4_mt14,
        nivel_5_mt14,
        nivel_6_mt14,
        nivel_7_mt14,
        nivel_8_mt14,
        nivel_9_mt14,
        nivel_10_mt14
    from {{ ref('stg_saeb_resultados_municipios') }}
    where dependencia_adm = 'Total - Federal, Estadual e Municipal'
      and localizacao = 'Total'
),

com_variacao as (
    select
        *,
        case
            when ano between 2019 and 2021 then 'pre_nem'
            when ano between 2022 and 2023 then 'implementacao_nem'
            when ano between 2024 and 2025 then 'pos_nem'
        end as periodo_nem,
        (media_12_lp + media_12_mt) / 2.0 as media_12_lp_mt,
        media_12_lp - lag(media_12_lp) over (partition by id_municipio order by ano) as delta_media_12_lp,
        media_12_mt - lag(media_12_mt) over (partition by id_municipio order by ano) as delta_media_12_mt,
        ((media_12_lp + media_12_mt) / 2.0) - lag((media_12_lp + media_12_mt) / 2.0) over (partition by id_municipio order by ano) as delta_media_12_lp_mt
    from saeb_canonico
)

select
    *,
    1 as tem_saeb_no_ano
from com_variacao
