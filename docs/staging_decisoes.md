# Documentação da staging e decisões de modelagem

Este documento registra o que entrou na camada `staging`, de qual tabela veio cada grupo de features e quais decisões foram tomadas para preservar a qualidade analítica antes da camada intermediária.

## Objetivo da staging

A staging não deve responder sozinha às perguntas finais do projeto. Ela deve:

- padronizar nomes de colunas e tipos;
- preservar a granularidade original útil de cada fonte;
- manter valores nulos estruturais sem imputação;
- preservar escalas originais, especialmente a proficiência do SAEB;
- separar bases com granularidades diferentes;
- criar derivações mínimas necessárias para compatibilizar versões da mesma fonte;
- documentar limitações e diferenças entre anos.

A unidade principal de integração analítica continua sendo municipal, porque `id_municipio` permite cruzar SAEB, Censo Escolar, PIB, IBGE e diretório municipal. Ao mesmo tempo, a staging agora preserva grão escola/ano suficiente para derivar camadas intermediárias tanto de Ensino Médio quanto de Educação Básica, além de um eixo específico para cursos técnicos.

## Decisões gerais

| Decisão | Motivo |
|---|---|
| Usar `id_municipio` como chave territorial principal | É a chave comum entre SAEB municipal, Censo Escolar, PIB, IBGE e diretório municipal. |
| Manter chaves territoriais como texto | Evita perda de zeros à esquerda e padroniza joins. |
| Não imputar nulos na staging | Alguns nulos são estruturais, como colunas que não existem em todos os anos. |
| Separar Censo Escolar 2025 | O desenho de 2025 vem em tabelas temáticas e não é continuação direta da tabela larga de 2019-2024. |
| Territorializar tabelas temáticas de 2025 via `id_escola` | Permite levar `id_municipio`, UF e recortes escolares para matrícula, turma, docente, gestor e curso técnico. |
| Manter sinais de Educação Básica junto do núcleo de Ensino Médio | Permite montar intermediates tanto para contexto amplo de EB quanto para foco analítico em EM/NEM. |
| Unificar histórico de cursos técnicos 2023-2025 | Permite comparar oferta e matrículas técnicas antes e depois da reorganização temática de 2025. |
| Não converter média SAEB para 0-10 | `MEDIA_*` é proficiência na escala original do SAEB; conversão seria métrica derivada posterior. |
| Criar `in_med_padronizado` e harmonizar flags de nível em 2025 | Em 2025 não existe `IN_MED` no mesmo formato 2019-2024; a oferta geral precisa ser reconstruída a partir das flags específicas. |

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
| `nivel_*_LP12`, `nivel_*_MT12` | SAEB 2019, 2021, 2023 | Recorte comparável do ensino médio tradicional. |
| `nivel_*_LP13`, `nivel_*_MT13` | SAEB 2021, 2023 | Ensino médio integrado, disponível apenas em 2021 e 2023. |
| `nivel_*_LP14`, `nivel_*_MT14` | SAEB 2021, 2023 | Agregado tradicional + integrado, disponível apenas em 2021 e 2023. |
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
| Harmonização de nível | `in_bas`, `in_inf`, `in_fund`, `in_med`, `in_prof`, `in_prof_tec`, `in_eja` | Mantêm sinais mínimos da Educação Básica e permitem filtros posteriores por etapa. |
| Mediação | `in_mediacao_presencial`, `in_mediacao_semipresencial`, `in_mediacao_ead` | Ajudam a qualificar diferenças de oferta e atendimento. |
| Infraestrutura escolar | `in_biblioteca`, `in_biblioteca_sala_leitura`, `in_internet`, `in_internet_aprendizagem`, `in_laboratorio_ciencias`, `in_laboratorio_informatica`, `in_quadra_esportes`, `qt_salas_utilizadas` | Oferecem contexto físico e tecnológico para análises de EB e EM. |
| Matrículas | `qt_mat_bas`, `qt_mat_inf`, `qt_mat_fund`, `qt_mat_med`, `qt_mat_med_prop`, `qt_mat_med_ct`, `qt_mat_med_nm`, `qt_mat_med_int`, `qt_mat_prof`, `qt_mat_prof_tec` | Permitem acompanhar volume geral, contexto da EB e detalhamento do EM/técnico. |
| Docentes e turmas | `qt_doc_bas`, `qt_doc_fund`, `qt_doc_med`, `qt_doc_prof_tec`, `qt_tur_bas`, `qt_tur_fund`, `qt_tur_med`, `qt_tur_prof_tec`, `qt_tur_med_int` | Contexto estrutural da oferta escolar e capacidade de atendimento. |

Decisão metodológica: `IN_MED` é o indicador geral de oferta de ensino médio para 2019-2024. `in_bas` foi derivado de sinais de etapa (`in_inf`, `in_fund`, `in_med`, `in_prof`, `in_eja`) para evitar depender de colunas instáveis entre anos. As colunas detalhadas do EM que não existem em todos os anos permanecem nulas quando ausentes.

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
| Harmonização de nível | `in_bas`, `in_inf`, `in_fund`, `in_med`, `in_eja`, `in_prof`, `in_med_padronizado` | Reconstrói oferta geral por etapa e compatibiliza 2025 com o histórico anterior. |
| Itinerários e profissionalização | `tp_itinerario_formativo`, `in_itinerario_aprofundamento`, `in_itinerario_tecn_prof`, `in_profissionalizante` | Sinais diretos da organização do NEM e da articulação técnica. |
| Ensino comum, especial e EJA | flags `in_comum_*` e `in_esp_exclusiva_*` | Permitem distinguir modalidades de oferta do EM e demais etapas. |
| Infraestrutura escolar | `in_biblioteca`, `in_internet`, `in_internet_aprendizagem`, `in_laboratorio_ciencias`, `in_laboratorio_informatica`, `in_laboratorio_educ_prof`, `in_sala_oficinas_educ_prof`, `in_quadra_esportes`, `qt_salas_utilizadas` | Agrega contexto físico e tecnológico relevante para EB, EM e técnico. |

Decisão metodológica: `IN_COMUM_MEDIO_INTEGRADO` não é sinônimo de `IN_MED`. Ele representa uma modalidade específica. Por isso foram preservadas as flags específicas e criada a derivação de oferta geral `in_med`/`in_med_padronizado`.

### Tabela Matrícula 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_matricula.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Matricula_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e território | `ano`, `co_uf`, `sg_uf`, `id_municipio`, `id_escola`, `tp_dependencia`, `tp_localizacao` | Territorialização herdada da tabela escola, permitindo agregação municipal posterior. |
| Ensino médio | `qt_mat_med`, `qt_mat_med_prop`, `qt_mat_med_nm`, `qt_mat_med_int` | Núcleo de matrículas do EM e tempo integral. |
| Itinerário formativo | `qt_mat_med_ifa`, `qt_mat_med_ifa_ling`, `qt_mat_med_ifa_mate`, `qt_mat_med_ifa_cienc`, `qt_mat_med_ifa_huma` | Matrículas por aprofundamento formativo. |
| Itinerário técnico-profissional | `qt_mat_med_iftp_ct`, `qt_mat_med_iftp_qp`, `qt_mat_med_arti_iftp_ct`, `qt_mat_med_arti_iftp_qp` | Sinais fortes de implementação técnico-profissional em 2025. |
| Educação profissional | `qt_mat_prof`, `qt_mat_prof_tec`, `qt_mat_prof_tec_iftp_ct`, `qt_mat_prof_iftp_qp`, `qt_mat_prof_int`, `qt_mat_prof_tec_int` | Complementam a leitura de formação técnica/profissional. |

### Tabela Turma 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_turma.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Turma_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e território | `ano`, `co_uf`, `sg_uf`, `id_municipio`, `id_escola`, `tp_dependencia`, `tp_localizacao` | Permite agregar turmas com o mesmo recorte das demais tabelas. |
| Contexto EB | `qt_tur_bas`, `qt_tur_fund` | Dá contexto estrutural mais amplo para escola/ano. |
| Ensino médio | `qt_tur_med`, `qt_tur_med_prop`, `qt_tur_med_nm`, `qt_tur_med_int`, `qt_tur_med_ead` | Mede organização do EM em turmas. |
| Itinerários | `qt_tur_med_iftp_ct`, `qt_tur_med_iftp_qp`, `qt_tur_med_ifa`, `qt_tur_med_ifa_ling`, `qt_tur_med_ifa_mate`, `qt_tur_med_ifa_cienc`, `qt_tur_med_ifa_huma` | Aproxima a leitura da organização curricular do NEM. |
| Educação profissional e EJA | `qt_tur_prof`, `qt_tur_prof_tec`, `qt_tur_prof_tec_iftp_ct`, `qt_tur_prof_iftp_qp`, `qt_tur_prof_tec_int`, `qt_tur_eja_med`, `qt_tur_eja_med_tec` | Complementam o retrato técnico e da EJA no EM. |

### Tabela Docente 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_docente.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Docente_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e território | `ano`, `co_uf`, `sg_uf`, `id_municipio`, `id_escola`, `tp_dependencia`, `tp_localizacao` | Permite agregar docentes com o mesmo recorte escolar/municipal. |
| Contexto EB | `qt_doc_bas`, `qt_doc_fund` | Dá contexto docente mais amplo para a escola. |
| Ensino médio e técnico | `qt_doc_med`, `qt_doc_med_prop`, `qt_doc_med_iftp_ct`, `qt_doc_med_iftp_qp`, `qt_doc_med_nm`, `qt_doc_prof`, `qt_doc_prof_tec`, `qt_doc_prof_tec_iftp_ct`, `qt_doc_prof_iftp_qp`, `qt_doc_eja_med`, `qt_doc_eja_med_tec` | Permite avaliar capacidade docente ligada ao EM e à profissionalização. |
| Formação, vínculo e disciplinas | `qt_doc_bas_esco_em`, `qt_doc_bas_esco_sup_grad_licen`, `qt_doc_bas_esco_sup_pos_*`, `qt_doc_bas_vinculo_*`, `qt_doc_bas_disc_projeto_de_vida`, `qt_doc_bas_disc_profissiona`, `qt_doc_bas_disc_info_computacao` | Enriquece a análise da estrutura docente associada ao NEM. |

### Tabela Gestor 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_gestor.sql`

Granularidade: `ano + id_escola`

Tabela fonte: `Tabela_Gestor_Escolar_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e território | `ano`, `co_uf`, `sg_uf`, `id_municipio`, `id_escola`, `tp_dependencia`, `tp_localizacao` | Permite unir perfil de gestão ao restante do contexto escolar. |
| Perfil agregado | `qt_gest_bas`, recortes de sexo, raça/cor, idade e PCD | Preserva estrutura agregada da gestão escolar. |
| Formação e vínculo | `qt_gest_bas_esco_*`, `qt_gest_bas_vinculo_*` | Dá contexto institucional para análises explicativas. |
| Cargo, acesso e especialização | `qt_gest_bas_diretor`, `qt_gest_bas_outro`, `qt_gest_bas_acesso_cargo_*`, `qt_gest_bas_espec_ens_medio`, `qt_gest_bas_espec_gestao` | Oferece contexto complementar para gestão e implementação. |

## Cursos técnicos

### Tabela Curso Técnico 2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_2025_curso_tecnico.sql`

Granularidade: `ano + id_escola + id_area_curso_profissional + co_curso_educ_profissional`

Tabela fonte: `Tabela_Curso_Tecnico_2025`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave, território e descrição | `ano`, `co_uf`, `sg_uf`, `id_municipio`, `id_escola`, `no_entidade`, `tp_dependencia`, `tp_localizacao`, `id_area_curso_profissional`, `no_area_curso_profissional`, `co_curso_educ_profissional`, `no_curso_educ_profissional` | Preserva a granularidade do curso técnico e o recorte territorial. |
| Cursos e matrículas técnicas | `qt_curso_tec`, `qt_mat_curso_tec` | Mede oferta e volume de cursos técnicos. |
| Itinerário técnico-profissional | `qt_curso_tec_iftp`, `qt_mat_curso_tec_iftp`, `qt_curso_tec_iftp_ct`, `qt_mat_curso_tec_iftp_ct` | Mede cursos/matrículas ligados ao itinerário técnico-profissional. |
| Modalidades técnicas | `qt_curso_tec_nm`, `qt_mat_curso_tec_nm`, `qt_curso_tec_conc`, `qt_mat_curso_tec_conc`, `qt_curso_tec_subs`, `qt_mat_curso_tec_subs`, `qt_curso_tec_eja`, `qt_mat_curso_tec_eja` | Mantém recortes de forma de oferta técnica. |

### Histórico de cursos técnicos 2023-2025

Modelo: `models/staging/censo_escolar/stg_censo_escolar_curso_tecnico_2023_2025.sql`

Granularidade: `ano + id_escola + id_area_curso_profissional + co_curso_educ_profissional`

Tabelas fonte:

- `suplemento_cursos_tecnicos_2023`
- `suplemento_cursos_tecnicos_2024`
- `stg_censo_escolar_2025_curso_tecnico`

| Bloco | Features na staging | Justificativa |
|---|---|---|
| Chave e território | `ano`, `co_uf`, `sg_uf`, `no_uf`, `id_municipio`, `no_municipio`, `tp_dependencia`, `tp_localizacao`, `id_escola`, `no_entidade` | Permite comparação territorial e administrativa entre 2023, 2024 e 2025. |
| Chave do curso | `id_area_curso_profissional`, `no_area_curso_profissional`, `co_curso_educ_profissional`, `no_curso_educ_profissional` | Preserva comparabilidade de áreas e cursos. |
| Oferta técnica histórica | `qt_curso_tec`, `qt_mat_curso_tec`, `qt_curso_tec_ct`, `qt_mat_curso_tec_ct`, `qt_curso_tec_nm`, `qt_mat_curso_tec_nm`, `qt_curso_tec_conc`, `qt_mat_curso_tec_conc`, `qt_curso_tec_subs`, `qt_mat_curso_tec_subs`, `qt_curso_tec_eja`, `qt_mat_curso_tec_eja` | Mantém modalidades clássicas do técnico ao longo do tempo. |
| Itinerário técnico-profissional 2025 | `qt_curso_tec_iftp`, `qt_mat_curso_tec_iftp`, `qt_curso_tec_iftp_ct`, `qt_mat_curso_tec_iftp_ct` | Permite adicionar o eixo do NEM técnico sem perder o histórico pré-2025. |

## PIB municipal

Modelo: `models/staging/ibge/stg_ibge_pib_municipio.sql`

Granularidade: `id_municipio + ano`

Tabela fonte: `seeds/ibge_pib_municipios_clean.csv`

| Features na origem | Features na staging | Decisão aplicada |
|---|---|---|
| `id_municipio` | `id_municipio` | Mantido como texto. |
| `nome_municipio` | `nome_municipio` | Preservado para leitura e conferência. |
| `pib_2019` a `pib_2023` | `ano`, `pib` | Convertido de wide para long para facilitar análise temporal. |

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
| `unique` e chaves compostas | SAEB, Censo 2019-2024, Censo 2025, curso técnico histórico, PIB, IBGE e diretório municipal. |
| `accepted_values` | UF, anos, dependência administrativa, localização, flags `IN_*`, sexo, cor/raça e alfabetização. |
| Faixas numéricas | Proficiência SAEB, percentuais `nivel_*`, PIB, população, taxas e contagens. |
| Relacionamentos | `id_municipio` validado contra a seed municipal; tabelas temáticas de 2025 ligadas à tabela escola por `id_escola`. |
| Cobertura esperada | IBGE, PIB, alfabetização detalhada, diretório municipal e modelos temáticos 2025 carregados a partir das fontes previstas. |

## Tratamentos de qualidade aplicados na staging

Os tratamentos abaixo fazem parte da staging, porque são necessários para tornar as fontes comparáveis, auditáveis e seguras para agregação posterior. Eles não substituem a camada intermediária, mas garantem que a intermediate receba dados padronizados.

### Chaves e tipagem

- `CO_MUNICIPIO` foi padronizado para `id_municipio` e mantido como texto em SAEB, Censo Escolar e bases municipais do IBGE para evitar perda de zeros à esquerda e estabilizar joins.
- `CO_ENTIDADE` foi padronizado para `id_escola` e mantido como texto nas tabelas escolares do Censo.
- `CO_UF`, `SG_UF` e outras chaves territoriais foram mantidas como texto para preservar domínio e comparabilidade entre fontes.
- `ANO_SAEB` e `NU_ANO_CENSO` foram convertidos para inteiro, mantendo a leitura temporal consistente.
- Contagens `QT_*` foram convertidas para inteiro e métricas contínuas, como proficiência SAEB, taxa de alfabetização e PIB, foram convertidas para tipos numéricos compatíveis com análise.

### Harmonização de nomes e granularidade

- Colunas-chave foram renomeadas para um padrão comum entre fontes, como `id_municipio`, `id_escola`, `ano` e `ano_saeb`.
- O Censo Escolar 2025 foi mantido em tabelas temáticas separadas para respeitar a granularidade real de `escola`, `matrícula`, `turma`, `docente`, `gestor` e `curso técnico`.
- As tabelas temáticas de 2025 foram enriquecidas com território e recortes escolares via `id_escola`, para não perder capacidade de agregação municipal posterior.
- O histórico de cursos técnicos `2023-2025` foi padronizado em um único modelo, preservando área, curso, modalidade e recortes administrativos.

### Flags derivadas e compatibilização entre anos

- `in_med_padronizado` foi criado em 2025 porque o conceito de oferta de ensino médio passou a estar distribuído em várias flags específicas.
- `in_bas`, `in_inf`, `in_fund`, `in_med`, `in_eja` e `in_prof` foram harmonizados para permitir leitura comparável entre anos e entre o bloco 2019-2024 e o bloco 2025.
- `in_bas` em 2019-2024 foi derivado a partir das flags de etapa disponíveis, evitando depender de colunas instáveis entre anos.
- O tratamento foi conservador: a staging cria apenas indicadores operacionais mínimos de compatibilidade, sem gerar índices analíticos compostos.

### Nulos estruturais e diferenças de schema

- Nulos estruturais foram preservados quando uma coluna não existe em todos os anos ou quando determinado recorte não se aplica à escola/município.
- No Censo Escolar 2019-2024, colunas como `qt_mat_med_prop`, `qt_mat_med_ct`, `qt_mat_med_nm` e `qt_tur_med_int` permanecem nulas nos anos em que não existem no layout original.
- No SAEB, nulos de `MEDIA_*` e `nivel_*` foram mantidos quando o recorte não tem resultado divulgado.
- A staging não faz imputação de matrículas, docentes, turmas, PIB, população ou alfabetização.

### Tratamentos específicos por fonte

#### SAEB

- O arquivo de 2019 recebeu `ano_saeb = 2019` porque esse campo não vinha explicitamente na base.
- As médias `MEDIA_*` foram mantidas na escala original de proficiência, sem conversão para nota 0-10.
- Os níveis de proficiência `nivel_*` foram preservados como percentuais, porque são parte do dado analítico original.

#### Censo Escolar

- As tabelas escolares foram reduzidas ao conjunto de colunas mais relevantes para EB, EM, NEM, infraestrutura e articulação técnico-profissional.
- Em 2025, `matrícula`, `turma`, `docente`, `gestor` e `curso técnico` foram ligados à tabela `escola` para carregar `id_municipio`, `co_uf`, `sg_uf`, `tp_dependencia` e `tp_localizacao`.
- O histórico técnico 2023-2025 compatibilizou modalidades antigas, como concomitante, subsequente e EJA, com os recortes novos de itinerário técnico-profissional em 2025.

#### IBGE e diretórios

- O PIB municipal foi convertido de formato wide para long em `id_municipio + ano + pib`.
- A alfabetização detalhada do IBGE foi mantida no grão original `município + recortes sociais`, sem agregação precoce.
- O diretório municipal foi preservado como dimensão territorial de referência para relacionamentos e cobertura.

### O que não foi feito na staging

- Não houve imputação de nulos.
- Não houve padronização analítica por taxa, percentual ou índice composto.
- Não houve agregação escola -> município.
- Não houve cálculo de deltas antes/depois do SAEB.
- Não houve criação de métricas finais de implementação do NEM.

Esses pontos ficam para `intermediate` e `gold`, mas dependem diretamente da qualidade e da padronização já garantidas pela staging.

## Status atual de validação

- O EDA já validou granularidade, presença de chaves, compatibilidade territorial por `id_municipio` e comportamento estrutural de nulos nas bases usadas pela staging.
- A staging implementada já cobre `SAEB`, `Censo Escolar 2019-2025`, histórico técnico `2023-2025`, `PIB`, `IBGE municipal`, `IBGE alfabetização detalhada` e diretório municipal.
- Com a passagem dos testes dbt da staging, o projeto fica pronto para avançar para camadas `intermediate` tanto com foco em Ensino Médio/NEM quanto com uma leitura mais ampla de Educação Básica.

## O que ainda precisa ser decidido depois da staging

- Como agregar Censo Escolar de escola para município.
- Como ponderar médias e matrículas na camada intermediária.
- Como calcular deltas antes/depois do SAEB.
- Como separar análise comparável 2019-2024 de retrato pós-mudança 2025.
- Quais indicadores finais serão usados como proxies principais de implementação do NEM.
- Como articular indicadores de curso técnico com oferta, matrícula, docente e turma de EM na intermediate/gold.
