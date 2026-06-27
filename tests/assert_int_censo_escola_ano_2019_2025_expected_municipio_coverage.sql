with expected as (
    select 2019 as ano, 5570 as expected_municipios
    union all select 2020, 5570
    union all select 2021, 5570
    union all select 2022, 5570
    union all select 2023, 5570
    union all select 2024, 5570
    union all select 2025, 5571
),
actual as (
    select
        ano,
        count(distinct id_municipio) as actual_municipios
    from {{ ref('int_censo_escola_ano_2019_2025') }}
    group by ano
)
select
    e.ano,
    e.expected_municipios,
    a.actual_municipios
from expected e
left join actual a using (ano)
where coalesce(a.actual_municipios, -1) != e.expected_municipios
