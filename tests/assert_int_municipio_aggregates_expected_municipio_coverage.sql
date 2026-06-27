with expected_censo as (
    select 2019 as ano, 5570 as expected_municipios
    union all select 2020, 5570
    union all select 2021, 5570
    union all select 2022, 5570
    union all select 2023, 5570
    union all select 2024, 5570
    union all select 2025, 5571
),
expected_painel as (
    select 2019 as ano, 5571 as expected_municipios
    union all select 2020, 5571
    union all select 2021, 5571
    union all select 2022, 5571
    union all select 2023, 5571
    union all select 2024, 5571
    union all select 2025, 5571
),
actual as (
    select 'int_municipio_ano_oferta_educacional' as model_name, ano, count(distinct id_municipio) as actual_municipios
    from {{ ref('int_municipio_ano_oferta_educacional') }}
    group by ano
    union all
    select 'int_municipio_ano_nem' as model_name, ano, count(distinct id_municipio) as actual_municipios
    from {{ ref('int_municipio_ano_nem') }}
    group by ano
    union all
    select 'int_municipio_ano_tecnico' as model_name, ano, count(distinct id_municipio) as actual_municipios
    from {{ ref('int_municipio_ano_tecnico') }}
    group by ano
    union all
    select 'int_municipio_ano_contexto' as model_name, ano, count(distinct id_municipio) as actual_municipios
    from {{ ref('int_municipio_ano_contexto') }}
    group by ano
    union all
    select 'int_municipio_ano_painel_educacional' as model_name, ano, count(distinct id_municipio) as actual_municipios
    from {{ ref('int_municipio_ano_painel_educacional') }}
    group by ano
),
expected as (
    select 'int_municipio_ano_oferta_educacional' as model_name, ano, expected_municipios from expected_censo
    union all
    select 'int_municipio_ano_nem' as model_name, ano, expected_municipios from expected_censo
    union all
    select 'int_municipio_ano_tecnico' as model_name, ano, expected_municipios from expected_censo
    union all
    select 'int_municipio_ano_contexto' as model_name, ano, expected_municipios from expected_painel
    union all
    select 'int_municipio_ano_painel_educacional' as model_name, ano, expected_municipios from expected_painel
)
select
    e.model_name,
    e.ano,
    e.expected_municipios,
    a.actual_municipios
from expected e
left join actual a
    on e.model_name = a.model_name
   and e.ano = a.ano
where coalesce(a.actual_municipios, -1) != e.expected_municipios
