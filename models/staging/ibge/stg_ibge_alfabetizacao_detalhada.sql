select
    cast(id_municipio as varchar) as id_municipio,
    cast(cor_raca as varchar) as cor_raca,
    cast(sexo as varchar) as sexo,
    cast(grupo_idade as varchar) as grupo_idade,
    cast(alfabetizacao as varchar) as alfabetizacao,
    try_cast(populacao as integer) as populacao
from read_csv(
    'data/raw/br_ibge_censo_2022_alfabetizacao_grupo_idade_sexo_raca.csv.gz',
    delim=',',
    header=true,
    all_varchar=true
)
