select *
from {{ ref('stg_ibge_censo_municipio') }}
where
    domicilios < 0
    or populacao < 0
    or area <= 0
    or taxa_alfabetizacao < 0
    or taxa_alfabetizacao > 1
    or idade_mediana < 0
    or razao_sexo < 0
    or indice_envelhecimento < 0
    or populacao_indigena < 0
    or populacao_indigena_terra_indigena < 0
    or populacao_quilombola < 0
    or populacao_quilombola_territorio_quilombola < 0
