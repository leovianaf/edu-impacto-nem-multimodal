# Impacto Educacional do Novo Ensino Médio Multimodal

Repositório técnico para ingestão, padronização e análise de dados educacionais e socioeconômicos com foco no impacto do Novo Ensino Médio (NEM) no Brasil. O projeto cruza resultados agregados do SAEB 2019, 2021 e 2023 com microdados do Censo Escolar, histórico de cursos técnicos, indicadores de PIB municipal e dados de alfabetização do Censo IBGE, com o objetivo de montar um dataset que possibilite investigar correlações entre implementação do NEM, contexto socioeconômico, articulação técnico-profissional e desempenho acadêmico.

O principal desafio de engenharia de dados deste trabalho foi contornar a mascaragem dos códigos geográficos nos microdados do SAEB. Para isso, o pipeline foi estruturado para utilizar planilhas agregadas de resultados por município e reconciliá-las com bases auxiliares e microdados do Censo Escolar, preservando rastreabilidade, reprodutibilidade, respeito à LGPD e consistência analítica.

## Estado Atual

O pipeline possui as camadas `staging`, `intermediate` e `serving` consolidadas e validadas. A serving concentra os indicadores analíticos de Ensino Médio e NEM, enriquecidos pelo histórico de educação técnica, e pode ser publicada nos bancos de consumo pelo script `scripts/load_serving_nosql.py`.

O MongoDB recebe um espelho documental das seis tabelas finais. O Neo4j recebe um grafo derivado dessas mesmas saídas, com municípios, escolas, anos e seus relacionamentos. A publicação usa lotes e operações idempotentes para permitir nova execução sem duplicar registros.

Ainda não existe uma fonte explícita de abandono/reprovação escolar no pipeline, então esses indicadores continuam como lacuna até uma nova entrada na staging.

## Qualidade E Limitações

A tabela abaixo resume as limitações originais das fontes e o que foi feito na pipeline, principalmente na `staging` e na `intermediate`, para torná-las utilizáveis na análise.

| Fonte                     | Limitação original                                               | O que a pipeline resolveu                                                                    | Garantia resultante                                                   |
| ------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| SAEB municipal            | identificadores geográficos mascarados nos microdados            | uso de resultados agregados por município e reconciliação com chaves territoriais auxiliares | cruzamento municipal viável sem expor microdados sensíveis            |
| Censo Escolar 2019-2024   | arquivo largo com colunas heterogêneas entre anos                | padronização por escola/ano e compatibilização temporal na `intermediate`                    | série comparável para EB, EM e sinais do NEM                          |
| Censo Escolar 2025        | mudança estrutural para tabelas temáticas separadas              | territorialização por `id_escola` e junção das tabelas temáticas                             | base única escola/ano para matrícula, turma, docente, gestor e escola |
| Cursos técnicos 2023-2025 | granularidade separada por curso/área e layout diferente em 2025 | unificação histórica e agregação escola/ano                                                  | leitura consistente da oferta técnica sem perder rastreabilidade      |
| IBGE e PIB                | fontes estruturais com granularidade e periodicidade distintas   | chaves municipais normalizadas e reaplicação do contexto IBGE 2022 no painel                 | contexto socioeconômico comparável ao longo de 2019-2025              |

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
   - A camada `serving` consolida os produtos finais para análise estatística e publicação multimodal.
   - `scripts/load_serving_nosql.py` espelha as tabelas finais no MongoDB e deriva o grafo de municípios, escolas e anos no Neo4j.
   - A leitura do DuckDB e a escrita nos bancos ocorrem em lotes para manter o consumo de memória limitado.

## Como Rodar

> Execute os comandos dbt a partir da raiz do repositório. Os modelos de staging leem arquivos locais com caminhos relativos, como `data/raw/...` e `seeds/...`; se o comando for executado de dentro de `scripts/`, o DuckDB procurará esses caminhos dentro de `scripts/` e retornará erro de arquivo não encontrado.

### 1. Pré-requisitos

Opção A, local:

- Python 3.10+
- dbt Core 1.10.1 com adapter DuckDB 1.10.1, travados em `requirements.txt` para reprodutibilidade

Opção B, recomendada para ETL:

- Docker
- Docker Compose

MongoDB e Neo4j são necessários somente para a etapa final de publicação da serving. O `docker-compose.yml` fornece os dois serviços.

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

Fluxo único recomendado para construir e validar o pipeline via Docker Compose:

```bash
docker compose build --no-cache dbt
docker compose run --rm dbt dbt --version
docker compose run --rm dbt dbt seed --profiles-dir .
docker compose run --rm dbt dbt run --select staging intermediate serving --profiles-dir .
docker compose run --rm dbt dbt test --select staging intermediate serving --profiles-dir .
```

Esse fluxo cobre toda a cadeia do projeto, da `staging` até a `serving`. Se quiser uma inspeção visual da qualidade dos dados, use:

- [notebooks/02_validacao_intermediate.ipynb](notebooks/02_validacao_intermediate.ipynb), para inventário de `manifest.json` e `information_schema` da intermediate;
- [notebooks/03_validacao_serving.ipynb](notebooks/03_validacao_serving.ipynb), para validar a `serving` e explorar os indicadores analíticos finais.

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

### 5. Executar o pipeline dbt

O perfil já está configurado para usar um banco local DuckDB em `./edu_impacto_nem_multimodal.duckdb`.

Para rodar o projeto inteiro, use o fluxo único da seção 2 acima.

Para inspecionar as tabelas/views da staging com Pandas:

```bash
python scripts/auditar_staging_pandas.py --metadata-only
```

Também é possível auditar uma tabela específica com amostra, contagem de linhas e resumo de nulos:

```bash
python scripts/auditar_staging_pandas.py --table stg_ibge_pib_municipio --sample-size 10 --with-row-count --with-null-summary
```

Esse script localiza o banco DuckDB na raiz do projeto automaticamente, então também pode ser executado de dentro da pasta `scripts/`.

Resultado esperado do pipeline no estado atual do projeto:

- 13 modelos materializados como views na staging;
- intermediate consolidada e serving materializada;
- cobertura de SAEB, Censo Escolar 2019-2025, histórico técnico 2023-2025, PIB, IBGE municipal, alfabetização detalhada e diretório municipal;
- banco local DuckDB criado em `edu_impacto_nem_multimodal.duckdb`.

### 6. Documentação da staging

A documentação das decisões da staging está em [docs/staging_decisoes.md](docs/staging_decisoes.md). Ela registra:

- quais tabelas fonte alimentam cada staging;
- quais features foram preservadas;
- quais colunas foram renomeadas ou derivadas;
- por que o Censo Escolar 2025 foi separado em tabelas próprias;
- quais testes de qualidade sustentam a passagem para a camada intermediária.

### 7. Publicar a camada serving em MongoDB e Neo4j

Após materializar e testar a `serving` no DuckDB, publique os dados nos bancos de consumo final. O fluxo recomendado executa o script dentro do serviço `dbt`, usando a rede interna do Compose.

#### 7.1 Preparar os serviços

```bash
docker compose build dbt
docker compose up -d mongodb neo4j
docker compose ps
```

Aguarde até que `mongodb` e `neo4j` apareçam como `healthy`. O arquivo `edu_impacto_nem_multimodal.duckdb` deve existir na raiz do projeto e conter as seis tabelas `srv_*`.

Crie o `.env` a partir de `.env.example` e preencha todas as variáveis obrigatórias: `MONGO_URI`, `MONGO_DB`, `NEO4J_URI`, `NEO4J_USER` e `NEO4J_PASSWORD`. Para execução dentro do Compose, as URIs devem apontar para os serviços `mongodb` e `neo4j`, não para `localhost`. O arquivo é injetado no contêiner com `--env-from-file .env`.

#### 7.2 Validar sem gravar dados

```bash
docker compose run --rm \
  --env-from-file .env \
  dbt python scripts/load_serving_nosql.py --check-only
```

O modo `--check-only`:

- verifica se o arquivo DuckDB e as seis tabelas serving existem;
- testa a conexão e autenticação no MongoDB e no Neo4j;
- exibe a contagem de registros de cada tabela;
- não cria, substitui ou remove documentos, nós ou relacionamentos.

#### 7.3 Executar a publicação

```bash
docker compose run --rm \
  --env-from-file .env \
  dbt python scripts/load_serving_nosql.py
```

Por padrão, `--target all` publica nos dois bancos. Para publicar somente um destino, use:

```bash
# Somente MongoDB
docker compose run --rm \
  --env-from-file .env \
  dbt python scripts/load_serving_nosql.py --target mongodb

# Somente Neo4j
docker compose run --rm \
  --env-from-file .env \
  dbt python scripts/load_serving_nosql.py --target neo4j
```

Os valores aceitos por `--target` são `all`, `mongodb` e `neo4j`. A opção é útil para republicar apenas o grafo ou apenas as coleções após uma mudança específica, sem reescrever o outro banco.

Os nomes `mongodb` e `neo4j` são os endereços DNS dos serviços na rede interna do Compose. Não use `localhost` nesse comando: dentro do contêiner `dbt`, `localhost` apontaria para o próprio contêiner.

O carregador executa as seguintes etapas:

1. valida o DuckDB e as conexões com os bancos;
2. publica as seis tabelas `srv_*` como coleções no MongoDB;
3. cria índices únicos baseados nas chaves naturais de município/ano ou escola/ano;
4. cria no Neo4j os nós `Municipio`, `Escola` e `Ano`;
5. cria os relacionamentos `PAINEL_MUNICIPAL`, `PERTENCE_A` e `OFERTA_EM_TECNICO`.

A leitura usa `fetchmany` e mantém apenas um lote em memória. O tamanho padrão é de 1.000 registros e pode ser alterado com `NOSQL_BATCH_SIZE`:

```bash
docker compose run --rm \
  --env-from-file .env \
  -e NOSQL_BATCH_SIZE=500 \
  dbt python scripts/load_serving_nosql.py
```

Reduza o lote se a máquina continuar sob pressão de memória. Lotes menores reduzem o pico de RAM, mas aumentam o número de operações e o tempo total.

#### 7.4 Acompanhar e retomar

O terminal mostra o número do lote, a quantidade enviada e o total processado em cada tabela ou conjunto de nós. Em outro terminal, acompanhe os contêineres com:

```bash
docker stats edu-impacto-mongodb edu-impacto-neo4j
```

A publicação usa `upsert` no MongoDB e `MERGE` no Neo4j. Se o processo for interrompido, o mesmo comando pode ser executado novamente: registros já publicados são atualizados, não duplicados. O script sempre percorre as tabelas desde o início; ele não mantém checkpoint por lote.

Para conferir as coleções após a execução:

```bash
docker compose exec mongodb mongosh --quiet --eval \
  'const d=db.getSiblingDB("edu_impacto_nem"); d.getCollectionNames().sort().forEach(n => print(n + ": " + d[n].countDocuments({})))'
```

Para executar o script diretamente na máquina host, copie `.env.example` para `.env`, instale `requirements.txt` e use as URLs com `localhost`. Essa alternativa depende do ambiente Python local; o fluxo pelo Compose é o recomendado.

Se você quiser gerar o dicionário final da `serving` em Excel, rode:

```bash
python scripts/export_serving_dictionary.py
```

O arquivo será salvo em `docs/Dicionario_Serving.xlsx`, com uma aba de resumo e uma aba por tabela final.

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
│   ├── Dicionario_Serving.xlsx
│   └── Dicionario_Resultados_Saeb_2023.csv
├── models/
│   ├── staging/                            # Definição de fontes e padronização inicial
│   │   └── src_inep.yml
│   ├── intermediate/                       # Regras intermediárias de negócio e reconciliação
│   └── serving/                            # Camada final para consumo analítico e publicação
├── scripts/
│   ├── converter_saeb.py                   # Conversão de planilhas SAEB para CSV compactado
│   ├── export_serving_dictionary.py        # Exportação do dicionário da serving para Excel
│   └── load_serving_nosql.py               # Publicação em lotes no MongoDB e Neo4j
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
