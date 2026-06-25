select count(*) as n_linhas
from {{ ref('stg_ibge_censo_municipio') }}
having count(*) != 5570
