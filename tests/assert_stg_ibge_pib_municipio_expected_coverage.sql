select ano
from {{ ref('stg_ibge_pib_municipio') }}
group by ano
having count(distinct id_municipio) != 5570
