select
    ano,
    id_escola,
    co_curso_educ_profissional,
    id_area_curso_profissional,
    count(*) as n_linhas
from {{ ref('stg_censo_escolar_2025_curso_tecnico') }}
group by 1, 2, 3, 4
having count(*) > 1
