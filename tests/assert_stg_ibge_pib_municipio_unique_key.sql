select
    id_municipio,
    ano,
    count(*) as n_linhas
from {{ ref('stg_ibge_pib_municipio') }}
group by 1, 2
having count(*) > 1
