select *
from {{ ref('stg_saeb_resultados_municipios') }}
where ano_saeb = 2019
  and (
      nivel_0_lp13 is not null
      or nivel_0_mt13 is not null
      or nivel_0_lp14 is not null
      or nivel_0_mt14 is not null
  )
