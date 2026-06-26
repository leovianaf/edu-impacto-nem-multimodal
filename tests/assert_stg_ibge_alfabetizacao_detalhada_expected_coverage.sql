select count(*) as n_linhas
from {{ ref('stg_ibge_alfabetizacao_detalhada') }}
having count(*) != 779800
