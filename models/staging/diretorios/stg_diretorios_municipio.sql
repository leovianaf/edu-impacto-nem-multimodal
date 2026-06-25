select
    cast(id_municipio as varchar) as id_municipio,
    cast(nome as varchar) as nome_municipio,
    cast(id_uf as varchar) as id_uf,
    cast(sigla_uf as varchar) as sigla_uf,
    cast(nome_uf as varchar) as nome_uf,
    cast(nome_regiao as varchar) as nome_regiao,
    try_cast(capital_uf as integer) as capital_uf,
    try_cast(amazonia_legal as integer) as amazonia_legal,
    cast(centroide as varchar) as centroide
from read_csv(
    'seeds/br_bd_diretorios_brasil_municipio.csv',
    delim=',',
    header=true,
    all_varchar=true
)
