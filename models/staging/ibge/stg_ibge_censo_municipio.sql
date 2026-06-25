select
    cast(id_municipio as varchar) as id_municipio,
    cast(sigla_uf as varchar) as sigla_uf,
    try_cast(domicilios as integer) as domicilios,
    try_cast(populacao as integer) as populacao,
    try_cast(area as double) as area,
    try_cast(taxa_alfabetizacao as double) as taxa_alfabetizacao,
    try_cast(idade_mediana as double) as idade_mediana,
    try_cast(razao_sexo as double) as razao_sexo,
    try_cast(indice_envelhecimento as double) as indice_envelhecimento,
    try_cast(populacao_indigena as integer) as populacao_indigena,
    try_cast(populacao_indigena_terra_indigena as integer) as populacao_indigena_terra_indigena,
    try_cast(populacao_quilombola as integer) as populacao_quilombola,
    try_cast(populacao_quilombola_territorio_quilombola as integer) as populacao_quilombola_territorio_quilombola
from read_csv(
    'seeds/br_ibge_censo_2022_municipio.csv',
    delim=',',
    header=true,
    all_varchar=true
)
