# Documentação da staging e decisões de modelagem

Este documento registra o que entrou na camada `staging`, de qual tabela veio cada grupo de features e quais decisões foram tomadas para preservar a qualidade analítica antes da camada intermediária.

## Objetivo da staging

A staging não deve responder sozinha às perguntas finais do projeto. Ela deve:

- padronizar nomes de colunas e tipos;
- preservar a granularidade original útil de cada fonte;
- manter valores nulos estruturais sem imputação;
- preservar escalas originais, especialmente a proficiência do SAEB;
- separar bases com granularidades diferentes;
- criar apenas derivações mínimas necessárias para compatibilizar versões da mesma fonte;
- documentar limitações e diferenças entre anos.

A unidade inicial da análise final será municipal, porque `id_municipio` permite cruzar SAEB, Censo Escolar, PIB, IBGE e diretório municipal.

## Decisões gerais

| Decisão | Motivo |
|---|---|
| Usar `id_municipio` como chave territorial principal | É a chave comum entre SAEB municipal, Censo Escolar, PIB, IBGE e diretório municipal. |
| Manter chaves territoriais como texto | Evita perda de zeros à esquerda e padroniza joins. |
| Não imputar nulos na staging | Alguns nulos são estruturais, como colunas que não existem em todos os anos. |
| Separar Censo Escolar 2025 | O desenho de 2025 vem em tabelas temáticas e não é continuação direta da tabela larga de 2019-2024. |
| Criar PIB em formato longo | A análise temporal fica mais simples com `id_municipio + ano + pib`. |
| Não converter média SAEB para 0-10 | `MEDIA_*` é proficiência na escala original do SAEB; conversão seria métrica derivada posterior. |
| Criar `in_med_padronizado` apenas para 2025 | Em 2025 não existe `IN_MED` igual ao formato 2019-2024; a oferta geral precisa ser reconstruída a partir das flags específicas de ensino médio. |

## SAEB municipal

Modelo: `models/staging/saeb/stg_saeb_resultados_municipios.sql`

Granularidade: `ano_saeb + id_municipio + dependencia_adm + localizacao`

Tabelas fonte:

- `saeb_resultados_municipios_2019`
- `saeb_resultados_municipios_2021`
- `saeb_resultados_municipios_2023`

| Features na staging | Origem | Decisão aplicada |
|---|---|---|
| `co_uf`, `no_uf` | SAEB 2019, 2021, 2023 | Preservadas como recorte territorial. |
| `id_municipio`, `no_municipio` | `CO_MUNICIPIO`, `NO_MUNICIPIO` | `CO_MUNICIPIO` foi renomeado para `id_municipio` e mantido como texto. |
| `dependencia_adm` | `DEPENDENCIA_ADM` | Preservada para separar rede/recorte administrativo. |
| `localizacao` | `LOCALIZACAO` | Preservada para separar total, urbana e rural. |
| `media_5_lp`, `media_5_mt` | `MEDIA_5_LP`, `MEDIA_5_MT` | Preservadas na escala original do SAEB. |
| `media_9_lp`, `media_9_mt` | `MEDIA_9_LP`, `MEDIA_9_MT` | Preservadas na escala original do SAEB. |
| `media_12_lp`, `media_12_mt` | `MEDIA_12_LP`, `MEDIA_12_MT` | Principais médias comparáveis para ensino médio entre 2019, 2021 e 2023. |
| `nivel_*_LP5`, `nivel_*_MT5` | SAEB 2019, 2021, 2023 | Preservados como distribuição percentual de proficiência do 5º ano. |
| `nivel_*_LP9`, `nivel_*_MT9` | SAEB 2019, 2021, 2023 | Preservados como distribuição percentual de proficiência do 9º ano. |
| `nivel_*_LP12`, `nivel_*_MT12` | SAEB 2019, 2021, 2023 | Recorte comparável do ensino médio tradicional. |
| `nivel_*_LP13`, `nivel_*_MT13` | SAEB 2021, 2023 | Disponível apenas em 2021 e 2023; fica nulo em 2019. |
| `nivel_*_LP14`, `nivel_*_MT14` | SAEB 2021, 2023 | Disponível apenas em 2021 e 2023; fica nulo em 2019. |
| `ano_saeb` | `ANO_SAEB` ou criação manual | Criado como `2019` no arquivo de 2019, porque ele não trazia `ANO_SAEB`. |

Decisão metodológica: para antes/depois do ensino médio, o núcleo comparável é `media_12_lp`, `media_12_mt`, `nivel_*_LP12` e `nivel_*_MT12`. Os recortes `13` e `14` enriquecem o retrato pós-2019, mas não podem ser usados como série temporal completa desde 2019.

## Censo Escolar 2019-2024

Modelo: `models/staging/censo_escolar/stg_censo_escolar_escolas_2019_2024.sql`

Granularidade: `ano + id_escola`

Tabelas fonte:

- `microdados_ed_basica_2019`
- `microdados_ed_basica_2020`
- `microdados_ed_basica_2021`
- `microdados_ed_basica_2022`
- `microdados_ed_basica_2023`
- `microdados_ed_basica_2024`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Identificação e território | `ano`, `co_uf`, `sg_uf`, `no_uf`, `id_municipio`, `no_municipio`, `id_escola`, `no_entidade` | Permitem ligação territorial, auditoria de nomes e granularidade escola/ano. |
| Recorte escolar | `tp_dependencia`, `tp_localizacao` | Permitem separar rede administrativa e localização urbana/rural. |
| Oferta de ensino médio | `in_regular`, `in_med`, `in_prof`, `in_prof_tec` | Indicam presença geral de ensino regular, ensino médio e educação profissional/técnica. |
| Mediação | `in_mediacao_presencial`, `in_mediacao_semipresencial`, `in_mediacao_ead` | Preservadas porque ajudam a qualificar diferenças de oferta e atendimento. |
| Matrículas | `qt_mat_med`, `qt_mat_med_prop`, `qt_mat_med_ct`, `qt_mat_med_nm`, `qt_mat_med_int`, `qt_mat_prof`, `qt_mat_prof_tec` | Núcleo principal dos proxies de oferta, composição e tempo integral no ensino médio. |
| Docentes e turmas | `qt_doc_med`, `qt_doc_prof_tec`, `qt_tur_med`, `qt_tur_prof_tec`, `qt_tur_med_int` | Contexto estrutural da oferta escolar e capacidade de atendimento. |

Decisão metodológica: `IN_MED` é o indicador geral de oferta de ensino médio para 2019-2024. As colunas `qt_mat_med_prop`, `qt_mat_med_ct`, `qt_mat_med_nm` e `qt_tur_med_int` ficam nulas em anos nos quais não existem com essa estrutura; esses nulos são estruturais.

## Censo Escolar 2025

Em 2025, o Censo Escolar foi separado em tabelas temáticas. Por isso a staging também foi separada.

### Tabela Escola 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_escola.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Escola_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Identificação e território | `ano`, `co_uf`, `sg_uf`, `no_uf`, `id_municipio`, `no_municipio`, `id_escola`, `no_entidade` | Mantém ligação territorial e chave escolar. |
| Recorte escolar | `tp_dependencia`, `tp_localizacao` | Mantém rede administrativa e localização. |
| Oferta geral | `in_regular`, `in_profissionalizante` | Indicam oferta regular e profissionalizante em 2025. |
| Itinerários | `tp_itinerario_formativo`, `in_itinerario_aprofundamento`, `in_itinerario_tecn_prof` | São sinais diretos da organização do Novo Ensino Médio em 2025. |
| Ensino médio comum | `in_comum_medio_medio`, `in_comum_medio_integrado`, `in_comum_medio_fic`, `in_comum_medio_normal` | Permitem separar ensino médio regular, integrado, FIC e normal/magistério. |
| Educação especial e EJA | `in_esp_exclusiva_medio_medio`, `in_esp_exclusiva_medio_integr`, `in_esp_exclusiva_medio_fic`, `in_esp_exclusiva_medio_normal`, `in_comum_eja_medio`, `in_esp_exclusiva_eja_medio` | Preservam formas específicas de oferta de ensino médio. |
| Derivada mínima | `in_med_padronizado` | Reconstrói presença geral de ensino médio em 2025 a partir das flags específicas. |

Decisão metodológica: `IN_COMUM_MEDIO_INTEGRADO` não é sinônimo de `IN_MED`. Ele representa uma modalidade específica. Por isso foi criada `in_med_padronizado` para indicar oferta geral de ensino médio em 2025, mantendo as modalidades separadas.

### Tabela Matrícula 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_matricula.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Matricula_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave | `ano`, `id_escola` | Permite ligar com a tabela de escola de 2025. |
| Ensino médio | `qt_mat_med`, `qt_mat_med_prop`, `qt_mat_med_nm`, `qt_mat_med_int` | Núcleo de matrículas do ensino médio e tempo integral. |
| Itinerário formativo | `qt_mat_med_ifa`, `qt_mat_med_ifa_ling`, `qt_mat_med_ifa_mate`, `qt_mat_med_ifa_cienc`, `qt_mat_med_ifa_huma` | Matrículas por itinerário de formação geral/aprofundamento. |
| Itinerário técnico-profissional | `qt_mat_med_iftp_ct`, `qt_mat_med_iftp_qp`, `qt_mat_med_arti_iftp_ct`, `qt_mat_med_arti_iftp_qp` | Sinais fortes de implementação técnico-profissional em 2025. |
| Educação profissional | `qt_mat_prof`, `qt_mat_prof_tec`, `qt_mat_prof_tec_iftp_ct`, `qt_mat_prof_iftp_qp`, `qt_mat_prof_int`, `qt_mat_prof_tec_int` | Complementam a leitura de formação técnica/profissional. |

### Tabela Curso Técnico 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_curso_tecnico.sql`

Granularidade: `ano + id_escola + id_area_curso_profissional + co_curso_educ_profissional`

Tabela fonte: `Tabela_Curso_Tecnico_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e descrição | `ano`, `id_escola`, `id_area_curso_profissional`, `no_area_curso_profissional`, `co_curso_educ_profissional`, `no_curso_educ_profissional` | Preserva a granularidade de cursos técnicos. |
| Cursos e matrículas técnicas | `qt_curso_tec`, `qt_mat_curso_tec` | Mede oferta e volume de cursos técnicos. |
| Itinerário técnico-profissional | `qt_curso_tec_iftp`, `qt_mat_curso_tec_iftp`, `qt_curso_tec_iftp_ct`, `qt_mat_curso_tec_iftp_ct` | Mede cursos/matrículas ligados ao itinerário técnico-profissional. |
| Modalidades técnicas | `qt_curso_tec_nm`, `qt_mat_curso_tec_nm`, `qt_curso_tec_conc`, `qt_mat_curso_tec_conc`, `qt_curso_tec_subs`, `qt_mat_curso_tec_subs`, `qt_curso_tec_eja`, `qt_mat_curso_tec_eja` | Mantém recortes de forma de oferta técnica. |

## Features de infraestrutura do Censo Escolar

As features de infraestrutura, como internet, laboratório, salas e estrutura física, foram consideradas como contexto possível, mas não entraram no primeiro escopo da staging principal do NEM.

Decisão atual: não incluir no primeiro ciclo para manter a staging focada em desempenho, oferta, matrícula, itinerários e contexto socioeconômico municipal.

Decisão pendente: se a análise precisar explicar diferenças estruturais entre municípios, criar uma staging complementar de infraestrutura escolar, com colunas como `IN_INTERNET`, `IN_INTERNET_APRENDIZAGEM`, `IN_LABORATORIO_INFORMATICA`, `IN_LABORATORIO_CIENCIAS`, `IN_LABORATORIO_EDUC_PROF`, `IN_SALA_OFICINAS_EDUC_PROF` e `QT_SALAS_UTILIZADAS`, validando se existem em todos os anos desejados.

## PIB municipal

Modelo: `models/staging/ibge/stg_ibge_pib_municipio.sql`

Granularidade: `id_municipio + ano`

Tabela fonte: `seeds/ibge_pib_municipios_clean.csv`

| Features na origem | Features na staging | Decisão aplicada |
|---|---|---|
| `id_municipio` | `id_municipio` | Mantido como texto. |
| `nome_municipio` | `nome_municipio` | Preservado para leitura e conferência. |
| `pib_2019` a `pib_2023` | `ano`, `pib` | Convertido de wide para long para facilitar análise temporal. |

Decisão metodológica: a seed já chega limpa ao repositório, mas a limpeza anterior não está automatizada no pipeline. A staging filtra linhas válidas de município e preserva anos 2019-2023.

## IBGE Censo municipal

Modelo: `models/staging/ibge/stg_ibge_censo_municipio.sql`

Granularidade: `id_municipio`

Tabela fonte: `seeds/br_ibge_censo_2022_municipio.csv`

| Features na staging | Justificativa |
|---|---|
| `id_municipio`, `sigla_uf` | Chave territorial e recorte por UF. |
| `domicilios`, `populacao`, `area` | Contexto demográfico e escala municipal. |
| `taxa_alfabetizacao`, `idade_mediana`, `razao_sexo`, `indice_envelhecimento` | Indicadores sociais e demográficos para explicar diferenças entre municípios. |
| `populacao_indigena`, `populacao_indigena_terra_indigena`, `populacao_quilombola`, `populacao_quilombola_territorio_quilombola` | Contexto populacional específico preservado para análises estruturais. |

## IBGE alfabetização detalhada

Modelo: `models/staging/ibge/stg_ibge_alfabetizacao_detalhada.sql`

Granularidade: `id_municipio + cor_raca + sexo + grupo_idade + alfabetizacao`

Tabela fonte: `data/raw/br_ibge_censo_2022_alfabetizacao_grupo_idade_sexo_raca.csv.gz`

| Features na staging | Justificativa |
|---|---|
| `id_municipio` | Permite cruzar com demais bases municipais. |
| `cor_raca`, `sexo`, `grupo_idade`, `alfabetizacao` | Preserva recortes sociais da alfabetização. |
| `populacao` | Quantidade populacional da combinação; nulos são preservados como estruturais. |

Decisão metodológica: esta staging não agrega a alfabetização. A agregação municipal por faixa, sexo ou raça deve acontecer na intermediate.

## Diretório municipal

Modelo: `models/staging/diretorios/stg_diretorios_municipio.sql`

Granularidade: `id_municipio`

Tabela fonte: `seeds/br_bd_diretorios_brasil_municipio.csv`

| Features na staging | Justificativa |
|---|---|
| `id_municipio`, `nome_municipio` | Identificação territorial principal. |
| `id_uf`, `sigla_uf`, `nome_uf`, `nome_regiao` | Recortes territoriais para análise regional. |
| `capital_uf`, `amazonia_legal` | Flags territoriais de contexto. |
| `centroide` | Possibilita análises geográficas/mapas. |

## Testes de qualidade implementados

| Tipo de teste | Onde foi aplicado |
|---|---|
| `not_null` | Chaves, anos, campos territoriais e categorias essenciais. |
| `unique` e chaves compostas | SAEB, Censo 2019-2024, Censo 2025, PIB, IBGE e diretório municipal. |
| `accepted_values` | UF, anos, dependência administrativa, localização, flags `IN_*`, sexo, cor/raça e alfabetização. |
| Faixas numéricas | Proficiência SAEB, percentuais `nivel_*`, PIB, população, taxas e contagens. |
| Relacionamento territorial | `id_municipio` validado contra a seed municipal de referência. |
| Cobertura esperada | IBGE, PIB, alfabetização detalhada e diretório municipal. |

## O que ainda precisa ser decidido depois da staging

- Se as features de infraestrutura escolar entram em uma staging complementar.
- Como agregar Censo Escolar de escola para município.
- Como ponderar médias e matrículas na camada intermediária.
- Como calcular deltas antes/depois do SAEB.
- Como separar análise comparável 2019-2024 de retrato pós-mudança 2025.
- Quais indicadores finais serão usados como proxies principais de implementação do NEM.
