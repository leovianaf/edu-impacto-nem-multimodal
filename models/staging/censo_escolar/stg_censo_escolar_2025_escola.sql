select
    try_cast("NU_ANO_CENSO" as integer) as ano,
    cast("CO_UF" as varchar) as co_uf,
    cast("SG_UF" as varchar) as sg_uf,
    cast("NO_UF" as varchar) as no_uf,
    cast("CO_MUNICIPIO" as varchar) as id_municipio,
    cast("NO_MUNICIPIO" as varchar) as no_municipio,
    cast("CO_ENTIDADE" as varchar) as id_escola,
    cast("NO_ENTIDADE" as varchar) as no_entidade,
    try_cast("TP_DEPENDENCIA" as integer) as tp_dependencia,
    try_cast("TP_LOCALIZACAO" as integer) as tp_localizacao,
    try_cast("IN_REGULAR" as integer) as in_regular,
    try_cast("IN_PROFISSIONALIZANTE" as integer) as in_profissionalizante,
    try_cast("TP_ITINERARIO_FORMATIVO" as integer) as tp_itinerario_formativo,
    try_cast("IN_ITINERARIO_APROFUNDAMENTO" as integer) as in_itinerario_aprofundamento,
    try_cast("IN_ITINERARIO_TECN_PROF" as integer) as in_itinerario_tecn_prof,
    try_cast("IN_COMUM_MEDIO_MEDIO" as integer) as in_comum_medio_medio,
    try_cast("IN_COMUM_MEDIO_INTEGRADO" as integer) as in_comum_medio_integrado,
    try_cast("IN_COMUM_MEDIO_FIC" as integer) as in_comum_medio_fic,
    try_cast("IN_COMUM_MEDIO_NORMAL" as integer) as in_comum_medio_normal,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_MEDIO" as integer) as in_esp_exclusiva_medio_medio,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_INTEGR" as integer) as in_esp_exclusiva_medio_integr,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_FIC" as integer) as in_esp_exclusiva_medio_fic,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_NORMAL" as integer) as in_esp_exclusiva_medio_normal,
    try_cast("IN_COMUM_EJA_MEDIO" as integer) as in_comum_eja_medio,
    try_cast("IN_ESP_EXCLUSIVA_EJA_MEDIO" as integer) as in_esp_exclusiva_eja_medio,
    case
        when coalesce(try_cast("IN_COMUM_MEDIO_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_INTEGRADO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_FIC" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_NORMAL" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_INTEGR" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_FIC" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_NORMAL" as integer), 0) = 1
        then 1
        else 0
    end as in_med_padronizado
from read_csv(
    'data/raw/censo_escolar_2025/Tabela_Escola_2025.csv.gz',
    delim=';',
    header=true,
    all_varchar=true,
    ignore_errors=true
)
