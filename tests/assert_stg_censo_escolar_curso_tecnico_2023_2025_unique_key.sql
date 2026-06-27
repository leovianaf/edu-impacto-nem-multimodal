select
    ano,
    id_escola,
    co_curso_educ_profissional,
    id_area_curso_profissional,
    count(*) as n_linhas
from {{ ref('stg_censo_escolar_curso_tecnico_2023_2025') }}
group by 1, 2, 3, 4
having count(*) > 1
