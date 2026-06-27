with anos as (
    select 2019 as ano
    union all select 2020
    union all select 2021
    union all select 2022
    union all select 2023
    union all select 2024
    union all select 2025
),

municipios as (
    select
        id_municipio,
        nome_municipio,
        id_uf,
        sigla_uf,
        nome_uf,
        nome_regiao,
        capital_uf,
        amazonia_legal,
        centroide
    from {{ ref('stg_diretorios_municipio') }}
),

base as (
    select
        anos.ano,
        municipios.*
    from anos
    cross join municipios
),

alfabetizacao as (
    select
        id_municipio,
        sum(case when alfabetizacao = 'Alfabetizadas' then coalesce(populacao, 0) else 0 end) as populacao_alfabetizada_ibge,
        sum(case when alfabetizacao = 'Não alfabetizadas' then coalesce(populacao, 0) else 0 end) as populacao_nao_alfabetizada_ibge,
        sum(coalesce(populacao, 0)) as populacao_total_alfabetizacao_ibge
    from {{ ref('stg_ibge_alfabetizacao_detalhada') }}
    group by id_municipio
)

select
    base.ano,
    base.id_municipio,
    base.nome_municipio,
    base.id_uf,
    base.sigla_uf,
    base.nome_uf,
    base.nome_regiao,
    base.capital_uf,
    base.amazonia_legal,
    base.centroide,
    2022 as ano_base_ibge_contexto,
    pib.pib,
    case when pib.pib is not null then 1 else 0 end as tem_pib_no_ano,
    censo.domicilios,
    censo.populacao,
    censo.area,
    censo.taxa_alfabetizacao,
    censo.idade_mediana,
    censo.razao_sexo,
    censo.indice_envelhecimento,
    censo.populacao_indigena,
    censo.populacao_indigena_terra_indigena,
    censo.populacao_quilombola,
    censo.populacao_quilombola_territorio_quilombola,
    alfabetizacao.populacao_alfabetizada_ibge,
    alfabetizacao.populacao_nao_alfabetizada_ibge,
    alfabetizacao.populacao_total_alfabetizacao_ibge,
    case
        when alfabetizacao.populacao_total_alfabetizacao_ibge > 0
        then alfabetizacao.populacao_alfabetizada_ibge * 1.0 / alfabetizacao.populacao_total_alfabetizacao_ibge
        else null
    end as taxa_alfabetizacao_detalhada_calculada,
    case
        when base.ano between 2019 and 2021 then 'pre_nem'
        when base.ano between 2022 and 2023 then 'implementacao_nem'
        when base.ano between 2024 and 2025 then 'pos_nem'
    end as periodo_nem
from base
left join {{ ref('stg_ibge_pib_municipio') }} as pib
    on base.id_municipio = pib.id_municipio
   and base.ano = pib.ano
left join {{ ref('stg_ibge_censo_municipio') }} as censo
    on base.id_municipio = censo.id_municipio
left join alfabetizacao
    on base.id_municipio = alfabetizacao.id_municipio
