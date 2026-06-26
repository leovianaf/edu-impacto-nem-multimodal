select *
from {{ ref('stg_ibge_pib_municipio') }}
where pib < 0
