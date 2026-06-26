select *
from {{ ref('stg_ibge_alfabetizacao_detalhada') }}
where populacao < 0
