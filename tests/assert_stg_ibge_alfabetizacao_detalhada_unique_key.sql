select
    id_municipio,
    cor_raca,
    sexo,
    grupo_idade,
    alfabetizacao,
    count(*) as n_linhas
from {{ ref('stg_ibge_alfabetizacao_detalhada') }}
group by 1, 2, 3, 4, 5
having count(*) > 1
