with fonte as (
    select
        cast(id_municipio as varchar) as id_municipio,
        cast(nome_municipio as varchar) as nome_municipio,
        try_cast(pib_2019 as double) as pib_2019,
        try_cast(pib_2020 as double) as pib_2020,
        try_cast(pib_2021 as double) as pib_2021,
        try_cast(pib_2022 as double) as pib_2022,
        try_cast(pib_2023 as double) as pib_2023
    from {{ ref('ibge_pib_municipios_clean') }}
    where regexp_matches(cast(id_municipio as varchar), '^[0-9]{7}$')
),

pib_longo as (
    select id_municipio, nome_municipio, 2019 as ano, pib_2019 as pib from fonte
    union all
    select id_municipio, nome_municipio, 2020 as ano, pib_2020 as pib from fonte
    union all
    select id_municipio, nome_municipio, 2021 as ano, pib_2021 as pib from fonte
    union all
    select id_municipio, nome_municipio, 2022 as ano, pib_2022 as pib from fonte
    union all
    select id_municipio, nome_municipio, 2023 as ano, pib_2023 as pib from fonte
)

select
    id_municipio,
    nome_municipio,
    ano,
    pib
from pib_longo
