select count(*) as n_linhas
from {{ ref('stg_diretorios_municipio') }}
having count(*) != 5571
