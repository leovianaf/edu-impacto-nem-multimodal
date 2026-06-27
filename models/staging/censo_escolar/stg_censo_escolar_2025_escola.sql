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
    try_cast("IN_BIBLIOTECA" as integer) as in_biblioteca,
    try_cast("IN_BIBLIOTECA_SALA_LEITURA" as integer) as in_biblioteca_sala_leitura,
    try_cast("IN_INTERNET" as integer) as in_internet,
    try_cast("IN_INTERNET_APRENDIZAGEM" as integer) as in_internet_aprendizagem,
    try_cast("IN_LABORATORIO_CIENCIAS" as integer) as in_laboratorio_ciencias,
    try_cast("IN_LABORATORIO_INFORMATICA" as integer) as in_laboratorio_informatica,
    try_cast("IN_LABORATORIO_EDUC_PROF" as integer) as in_laboratorio_educ_prof,
    try_cast("IN_SALA_OFICINAS_EDUC_PROF" as integer) as in_sala_oficinas_educ_prof,
    try_cast("IN_QUADRA_ESPORTES" as integer) as in_quadra_esportes,
    try_cast("QT_SALAS_UTILIZADAS" as integer) as qt_salas_utilizadas,
    try_cast("IN_COMUM_CRECHE" as integer) as in_comum_creche,
    try_cast("IN_COMUM_PRE" as integer) as in_comum_pre,
    try_cast("IN_COMUM_FUND_AI" as integer) as in_comum_fund_ai,
    try_cast("IN_COMUM_FUND_AF" as integer) as in_comum_fund_af,
    try_cast("IN_COMUM_MEDIO_MEDIO" as integer) as in_comum_medio_medio,
    try_cast("IN_COMUM_MEDIO_INTEGRADO" as integer) as in_comum_medio_integrado,
    try_cast("IN_COMUM_MEDIO_FIC" as integer) as in_comum_medio_fic,
    try_cast("IN_COMUM_MEDIO_NORMAL" as integer) as in_comum_medio_normal,
    try_cast("IN_ESP_EXCLUSIVA_CRECHE" as integer) as in_esp_exclusiva_creche,
    try_cast("IN_ESP_EXCLUSIVA_PRE" as integer) as in_esp_exclusiva_pre,
    try_cast("IN_ESP_EXCLUSIVA_FUND_AI" as integer) as in_esp_exclusiva_fund_ai,
    try_cast("IN_ESP_EXCLUSIVA_FUND_AF" as integer) as in_esp_exclusiva_fund_af,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_MEDIO" as integer) as in_esp_exclusiva_medio_medio,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_INTEGR" as integer) as in_esp_exclusiva_medio_integr,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_FIC" as integer) as in_esp_exclusiva_medio_fic,
    try_cast("IN_ESP_EXCLUSIVA_MEDIO_NORMAL" as integer) as in_esp_exclusiva_medio_normal,
    try_cast("IN_COMUM_EJA_FUND" as integer) as in_comum_eja_fund,
    try_cast("IN_COMUM_EJA_MEDIO" as integer) as in_comum_eja_medio,
    try_cast("IN_COMUM_EJA_PROF" as integer) as in_comum_eja_prof,
    try_cast("IN_ESP_EXCLUSIVA_EJA_FUND" as integer) as in_esp_exclusiva_eja_fund,
    try_cast("IN_ESP_EXCLUSIVA_EJA_MEDIO" as integer) as in_esp_exclusiva_eja_medio,
    try_cast("IN_ESP_EXCLUSIVA_EJA_PROF" as integer) as in_esp_exclusiva_eja_prof,
    try_cast("IN_COMUM_PROF" as integer) as in_comum_prof,
    try_cast("IN_ESP_EXCLUSIVA_PROF" as integer) as in_esp_exclusiva_prof,
    case
        when coalesce(try_cast("IN_COMUM_CRECHE" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_PRE" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_CRECHE" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_PRE" as integer), 0) = 1
        then 1
        else 0
    end as in_inf,
    case
        when coalesce(try_cast("IN_COMUM_FUND_AI" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_FUND_AF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_FUND_AI" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_FUND_AF" as integer), 0) = 1
        then 1
        else 0
    end as in_fund,
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
    end as in_med,
    case
        when coalesce(try_cast("IN_COMUM_EJA_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_EJA_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_EJA_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_PROF" as integer), 0) = 1
        then 1
        else 0
    end as in_eja,
    case
        when coalesce(try_cast("IN_PROFISSIONALIZANTE" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_PROF" as integer), 0) = 1
        then 1
        else 0
    end as in_prof,
    case
        when coalesce(try_cast("IN_COMUM_CRECHE" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_PRE" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_FUND_AI" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_FUND_AF" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_INTEGRADO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_FIC" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_MEDIO_NORMAL" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_EJA_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_EJA_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_EJA_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_COMUM_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_CRECHE" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_PRE" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_FUND_AI" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_FUND_AF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_INTEGR" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_FIC" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_MEDIO_NORMAL" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_FUND" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_MEDIO" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_EJA_PROF" as integer), 0) = 1
          or coalesce(try_cast("IN_ESP_EXCLUSIVA_PROF" as integer), 0) = 1
        then 1
        else 0
    end as in_bas,
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
