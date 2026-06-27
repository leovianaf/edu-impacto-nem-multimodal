# Impacto Educacional do Novo Ensino Médio Multimodal

Repositório técnico para ingestão, padronização e análise de dados educacionais e socioeconômicos com foco no impacto do Novo Ensino Médio (NEM) no Brasil. O projeto cruza resultados agregados do SAEB 2019, 2021 e 2023 com microdados do Censo Escolar, histórico de cursos técnicos, indicadores de PIB municipal e dados de alfabetização do Censo IBGE, com o objetivo de montar um dataset que possibilite investigar correlações entre implementação do NEM, contexto socioeconômico, articulação técnico-profissional e desempenho acadêmico.

O principal desafio de engenharia de dados deste trabalho foi contornar a mascaragem dos códigos geográficos nos microdados do SAEB. Para isso, o pipeline foi estruturado para utilizar planilhas agregadas de resultados por município e reconciliá-las com bases auxiliares e microdados do Censo Escolar, preservando rastreabilidade, reprodutibilidade, respeito à LGPD e consistência analítica.

## Estado Atual

O pipeline já tem a camada `staging` e a `intermediate` consolidadas e validadas. A etapa seguinte é a `serving`/`gold`, com foco principal no Ensino Médio e na extração de indicadores analíticos para o NEM, mantendo o histórico técnico como enriquecimento da leitura.

## Qualidade E Limitações

A tabela abaixo resume as limitações originais das fontes e o que foi feito na pipeline, principalmente na `staging` e na `intermediate`, para torná-las utilizáveis na análise.

| Fonte | Limitação original | O que a pipeline resolveu | Garantia resultante |
| --- | --- | --- | --- |
| SAEB municipal | identificadores geográficos mascarados nos microdados | uso de resultados agregados por município e reconciliação com chaves territoriais auxiliares | cruzamento municipal viável sem expor microdados sensíveis |
| Censo Escolar 2019-2024 | arquivo largo com colunas heterogêneas entre anos | padronização por escola/ano e compatibilização temporal na `intermediate` | série comparável para EB, EM e sinais do NEM |
| Censo Escolar 2025 | mudança estrutural para tabelas temáticas separadas | territorialização por `id_escola` e junção das tabelas temáticas | base única escola/ano para matrícula, turma, docente, gestor e escola |
| Cursos técnicos 2023-2025 | granularidade separada por curso/área e layout diferente em 2025 | unificação histórica e agregação escola/ano | leitura consistente da oferta técnica sem perder rastreabilidade |
| IBGE e PIB | fontes estruturais com granularidade e periodicidade distintas | chaves municipais normalizadas e reaplicação do contexto IBGE 2022 no painel | contexto socioeconômico comparável ao longo de 2019-2025 |

Essas garantias se referem à pipeline construída. Elas não eliminam as limitações inerentes às fontes originais, mas tornam explícito o que foi harmonizado para uso analítico.

## Objetivo Analítico

O projeto busca responder, entre outras, às seguintes questões:

- Existe correlação entre a implementação do NEM e a variação de desempenho acadêmico observada no SAEB?
- Como sinais de oferta de Ensino Médio, tempo integral, itinerários formativos e articulação técnico-profissional se relacionam com o desempenho acadêmico?
- Como a oferta de cursos técnicos e de educação profissional pode enriquecer a leitura da implementação do NEM quando associada ao Ensino Médio?
- Como indicadores socioeconômicos municipais, como PIB e alfabetização, se relacionam com os resultados educacionais?
- Quais sinais estruturais emergem ao integrar diferentes fontes públicas em uma camada analítica única?

## Stack Tecnológica

| Camada                        | Tecnologia      | Finalidade                                                                                        |
| ----------------------------- | --------------- | ------------------------------------------------------------------------------------------------- |
| Ingestão e preparação         | Python          | Automação da leitura, conversão e compressão dos arquivos brutos                                  |
| Manipulação tabular           | Pandas          | Limpeza, transformação inicial e exportação dos datasets                                          |
| Leitura de planilhas binárias | Pyxlsb          | Extração de dados `.xlsb` do SAEB                                                                 |
| Transformação analítica       | dbt             | Padronização, modelagem e versionamento das transformações                                        |
| Engine analítica              | DuckDB          | Execução local do pipeline SQL e persistência analítica                                           |
| Camada serving                | MongoDB e Neo4j | Persistência da camada final para análises multimodais, consultas documentais e relações em grafo |

## Arquitetura do Pipeline

O fluxo de dados foi desenhado para isolar claramente ingestão, padronização e consumo analítico.

1. **Extração e conversão dos dados brutos**
   - Os arquivos originais do SAEB, do Censo Escolar e do Censo IBGE 2022 são armazenados em `data/raw/`.
   - Scripts Python em `scripts/` convertem arquivos `.xlsx` e `.xlsb` para `.csv.gz`, reduzindo custo de armazenamento e simplificando leitura pelo dbt/DuckDB.

2. **Padronização e definição de fontes**
   - As fontes raw são registradas em `models/staging/src_inep.yml`.
   - O dbt referencia diretamente os arquivos comprimidos por ano, mantendo a camada de staging desacoplada da origem manual.

3. **Transformação e enriquecimento**
   - A modelagem em `models/` organiza a transformação por camadas (`staging`, `intermediate`, `serving`).
   - Seeds em `seeds/` fornecem dados auxiliares estruturados, como códigos municipais, PIB e bases do IBGE.

4. **Persistência e consumo analítico**
   - A camada final consolida insumos para análise estatística, exploração em ferramentas de consumo e publicação multimodal.
   - Quando a `serving`/`gold` estiver pronta, os dados podem ser enviados para MongoDB e Neo4j.

## Como Rodar

> Execute os comandos dbt a partir da raiz do repositório. Os modelos de staging leem arquivos locais com caminhos relativos, como `data/raw/...` e `seeds/...`; se o comando for executado de dentro de `scripts/`, o DuckDB procurará esses caminhos dentro de `scripts/` e retornará erro de arquivo não encontrado.

### 1. Pré-requisitos

Opção A, local:

- Python 3.10+
- dbt Core 1.10.1 com adapter DuckDB 1.10.1, travados em `requirements.txt` para reprodutibilidade

Opção B, recomendada para ETL:

- Docker
- Docker Compose

MongoDB e Neo4j não são pré-requisitos nesta etapa. Eles entram depois, quando a camada `gold/serving` estiver pronta para publicação.

### 2. Subir ambiente dbt + DuckDB

#### Opção A. Ambiente virtual local

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### Opção B. Docker Compose

Construir a imagem do serviço dbt:

```bash
docker compose build dbt
```

Checar a instalação do dbt no container:

```bash
docker compose run --rm dbt dbt --version
```

Passo a passo mínimo para construir e validar a staging com Docker Compose:

```bash
docker compose run --rm dbt dbt seed --profiles-dir .
docker compose run --rm dbt dbt run --select staging --profiles-dir .
docker compose run --rm dbt dbt test --select staging --profiles-dir .
```

Depois de fechar a `staging`, o fluxo natural do projeto segue para a `intermediate`:

```bash
docker compose run --rm dbt dbt run --select staging intermediate --profiles-dir .
docker compose run --rm dbt dbt test --select staging intermediate --profiles-dir .
```

A `intermediate` já foi validada com testes de cobertura municipal e reconciliação escola -> município. A partir daqui, o foco passa a ser a construção da `serving` com recortes orientados ao EM/NEM.

Abrir um shell no container, montando o repositório inteiro em `/workspace`:

```bash
docker compose run --rm dbt bash
```

O arquivo `edu_impacto_nem_multimodal.duckdb` continuará sendo criado na raiz do projeto, porque o `profiles.yml` aponta para `./edu_impacto_nem_multimodal.duckdb` e o diretório de trabalho do container é `/workspace`.

### 3. Disponibilizar os dados brutos

[**Link para download dos arquivos raw**](https://drive.google.com/file/d/1vudFbQ9QdjMvLoF5VEK0Wlsy9PPdaWAt/view?usp=sharing)

Os dados brutos não devem ser versionados no Git. Eles devem ficar apenas localmente em `data/raw/`, que está ignorado no `.gitignore`. As seeds em `seeds/` e os dicionários em `docs/` permanecem versionados porque são arquivos auxiliares menores e necessários para reprodutibilidade.

**Fontes originais dos dados raw**

- Resultados SAEB (2019, 2021, 2023): [Site INEP Resultados SAEB](https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/saeb/resultados)
- Censo Escolar (2019-2025): [Microdados INEP Censo Escolar](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar)
- PIB Municipal (2019-2023): [SIDRA IBGE PIB](https://sidra.ibge.gov.br/tabela/5938/)
- Censo IBGE / alfabetização: [Censo 2022 - Alfabetização por Sexo, Raça e Grupo de Idade](https://basedosdados.org/dataset/08a1546e-251f-4546-9fe0-b1e6ab2b203d?table=cf9537b5-6198-455f-a8b0-7c762e94d79c)
- Censo IBGE / municípios: [Censo 2022 - Municípios](https://basedosdados.org/dataset/08a1546e-251f-4546-9fe0-b1e6ab2b203d?table=707fd42e-95e0-4856-922f-fcbb55db913a)
- Censo IBGE / diretórios: [Censo 2022 - Diretórios Brasileiros](https://basedosdados.org/dataset/33b49786-fb5f-496f-bb7c-9811c985af8e?table=dffb65ac-9df9-4151-94bf-88c45bfcb056)

Para o PIB municipal, os filtros aplicados na extração foram:

- Produto Interno Bruto a preços correntes (Mil Reais);
- Ano de referência entre 2019 e 2023;
- Recorte municipal completo, todos os 5570 municípios brasileiros.

Depois do download, organize os arquivos dentro de `data/raw/` conforme a convenção usada pelos modelos dbt, por exemplo:

```text
data/raw/
├── censo_escolar_2019/
│   └── microdados_ed_basica_2019.csv.gz
├── censo_escolar_2020/
│   └── microdados_ed_basica_2020.csv.gz
├── censo_escolar_2021/
│   └── microdados_ed_basica_2021.csv.gz
├── censo_escolar_2022/
│   └── microdados_ed_basica_2022.csv.gz
├── censo_escolar_2023/
│   └── microdados_ed_basica_2023.csv.gz
├── censo_escolar_2024/
│   └── microdados_ed_basica_2024.csv.gz
├── censo_escolar_2025/
│   ├── Tabela_Docente_2025.csv.gz
│   ├── Tabela_Escola_2025.csv.gz
│   ├── Tabela_Gestor_Escolar_2025.csv.gz
│   ├── Tabela_Matricula_2025.csv.gz
│   ├── Tabela_Turma_2025.csv.gz
│   └── Tabela_Curso_Tecnico_2025.csv.gz
├── saeb_2019/
│   └── saeb_resultados_municipios_2019.csv.gz
├── saeb_2021/
│   └── saeb_resultados_municipios_2021.csv.gz
├── saeb_2023/
│   └── saeb_resultados_municipios_2023.csv.gz
└── br_ibge_censo_2022_alfabetizacao_grupo_idade_sexo_raca.csv.gz
```

### 4. Converter planilhas para `.csv.gz`

O script [scripts/converter_saeb.py](scripts/converter_saeb.py) realiza a leitura de planilhas do SAEB e exporta arquivos compactados.

Antes de executar, ajuste no script:

- `caminho_arquivo`
- `caminho_saida_dados`
- `caminho_saida_dicionario`
- Ano e formato correspondente (`.xlsx` ou `.xlsb`)

Execução:

```bash
python scripts/converter_saeb.py
```

### 5. Executar seeds e staging no dbt

O perfil já está configurado para usar um banco local DuckDB em `./edu_impacto_nem_multimodal.duckdb`.

Se estiver usando Docker Compose, a ordem recomendada é:

```bash
docker compose build --no-cache dbt
docker compose run --rm dbt dbt --version
docker compose run --rm dbt dbt seed --profiles-dir .
docker compose run --rm dbt dbt run --select staging --profiles-dir .
docker compose run --rm dbt dbt test --select staging --profiles-dir .
```

Carregue as seeds auxiliares:

Local:

```bash
dbt seed --profiles-dir .
```

Com Docker Compose:

```bash
docker compose run --rm dbt dbt seed --profiles-dir .
```

Rode apenas a camada staging:

Local:

```bash
dbt run --select staging --profiles-dir .
```

Com Docker Compose:

```bash
docker compose run --rm dbt dbt run --select staging --profiles-dir .
```

Valide a camada staging:

Local:

```bash
dbt test --select staging --profiles-dir .
```

Com Docker Compose:

```bash
docker compose run --rm dbt dbt test --select staging --profiles-dir .
```

Para inspecionar as tabelas/views da staging com Pandas:

```bash
python scripts/auditar_staging_pandas.py --metadata-only
```

Também é possível auditar uma tabela específica com amostra, contagem de linhas e resumo de nulos:

```bash
python scripts/auditar_staging_pandas.py --table stg_ibge_pib_municipio --sample-size 10 --with-row-count --with-null-summary
```

Esse script localiza o banco DuckDB na raiz do projeto automaticamente, então também pode ser executado de dentro da pasta `scripts/`.

Resultado esperado da staging no estado atual do projeto:

- 13 modelos materializados como views;
- cobertura de SAEB, Censo Escolar 2019-2025, histórico técnico 2023-2025, PIB, IBGE municipal, alfabetização detalhada e diretório municipal;
- banco local DuckDB criado em `edu_impacto_nem_multimodal.duckdb`.

Para rodar todo o projeto dbt disponível:

Local:

```bash
dbt run --profiles-dir .
dbt test --profiles-dir .
```

Com Docker Compose:

```bash
docker compose run --rm dbt dbt run --profiles-dir .
docker compose run --rm dbt dbt test --profiles-dir .
```

### 6. Documentação da staging

A documentação das decisões da staging está em [docs/staging_decisoes.md](docs/staging_decisoes.md). Ela registra:

- quais tabelas fonte alimentam cada staging;
- quais features foram preservadas;
- quais colunas foram renomeadas ou derivadas;
- por que o Censo Escolar 2025 foi separado em tabelas próprias;
- quais testes de qualidade sustentam a passagem para a camada intermediária.

### 7. Publicar a camada serving em MongoDB e Neo4j

Após a materialização da camada `serving` no DuckDB, a etapa seguinte da arquitetura consiste na publicação dos dados para as bases de consumo final.

```bash
python scripts/load_serving_nosql.py
```

## Estrutura do Projeto

```text
edu-impacto-nem-multimodal/
├── data/
│   └── raw/
│       ├── censo_escolar_2019/             # Arquivos brutos do Censo Escolar por ano
│       ├── censo_escolar_2020/
│       ├── censo_escolar_2021/
│       ├── censo_escolar_2022/
│       ├── censo_escolar_2023/
│       ├── censo_escolar_2024/
│       ├── censo_escolar_2025/
│       ├── saeb_2019/                      # Resultados agregados do SAEB por município
│       ├── saeb_2021/
│       ├── saeb_2023/
│       └── .gitkeep
├── docs/
│   ├── Dicionario_Censo_Escolar_2019.xlsx
│   ├── Dicionario_Censo_Escolar_2020.xlsx
│   ├── Dicionario_Censo_Escolar_2021.xlsx
│   ├── Dicionario_Censo_Escolar_2022.xlsx
│   ├── Dicionario_Censo_Escolar_2023.xlsx
│   ├── Dicionario_Censo_Escolar_2024.xlsx
│   ├── Dicionario_Censo_Escolar_2025.xlsx
│   └── Dicionario_Resultados_Saeb_2023.csv
├── models/
│   ├── staging/                            # Definição de fontes e padronização inicial
│   │   └── src_inep.yml
│   ├── intermediate/                       # Regras intermediárias de negócio e reconciliação
│   └── serving/                            # Camada final para consumo analítico e publicação
├── scripts/
│   ├── converter_saeb.py                   # Conversão de planilhas SAEB para CSV compactado
│   └── load_gold_nosql.py                  # Publicação da camada serving em MongoDB e Neo4j
├── seeds/
│   ├── br_bd_diretorios_brasil_municipio.csv
│   ├── br_ibge_censo_2022_municipio.csv
│   └── ibge_pib_municipios_clean.csv
├── dbt_project.yml                         # Configuração do projeto dbt
├── profiles.yml                            # Perfil local do DuckDB
├── requirements.txt                        # Dependências Python
├── LICENSE                                 # Licença MIT
└── README.md
```

## Convenções de Dados

| Diretório              | Papel no pipeline                                              |
| ---------------------- | -------------------------------------------------------------- |
| `data/raw/`            | Armazenamento dos dados brutos, preferencialmente em `.csv.gz` |
| `scripts/`             | Automação da ingestão, conversão e publicação da camada final  |
| `models/staging/`      | Leitura de fontes e normalização inicial                       |
| `models/intermediate/` | Regras de integração, reconciliação e enriquecimento           |
| `models/serving/`      | Tabelas finais para análise e envio às bases de consumo        |
| `seeds/`               | Tabelas auxiliares versionadas no repositório                  |
| `docs/`                | Dicionários e documentação de apoio                            |

## Desafio Técnico Central

Os microdados do SAEB não disponibilizam de forma aberta todos os identificadores geográficos necessários para um cruzamento municipal direto em determinadas análises. A estratégia adotada neste repositório consiste em:

- utilizar planilhas de resultados agregados do SAEB por município;
- padronizar essas saídas em formato tabular comprimido;
- combinar os resultados com microdados do Censo Escolar e bases auxiliares territoriais;
- enriquecer a camada analítica com indicadores socioeconômicos municipais.

Essa abordagem permite construir uma base consistente para análises correlacionais sem depender exclusivamente dos microdados mascarados.

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
