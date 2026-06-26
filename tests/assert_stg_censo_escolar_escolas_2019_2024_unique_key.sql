select
    ano,
    id_escola,
    count(*) as n_linhas
from {{ ref('stg_censo_escolar_escolas_2019_2024') }}
group by 1, 2
having count(*) > 1
