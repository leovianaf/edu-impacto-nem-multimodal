select
    ano_saeb,
    id_municipio,
    dependencia_adm,
    localizacao,
    count(*) as n_linhas
from {{ ref('stg_saeb_resultados_municipios') }}
group by 1, 2, 3, 4
having count(*) > 1
