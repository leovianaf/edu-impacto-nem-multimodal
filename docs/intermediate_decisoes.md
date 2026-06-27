# Documentação da intermediate e decisões de modelagem

Este documento registra as decisões da camada `intermediate`, com foco em compatibilização temporal do Censo Escolar, construção do painel municipal e separação entre a camada analítica de trabalho e a camada final publicada.

## Papel da intermediate

A `intermediate` é a camada em que a staging deixa de ser apenas padronização técnica e passa a virar base analítica reaproveitável. Ela deve:

- compatibilizar o Censo Escolar 2019-2024 com o desenho temático de 2025;
- consolidar grãos úteis para análise em `escola/ano` e `municipio/ano`;
- explicitar o que é comparável entre anos e o que só existe em parte da série;
- criar variáveis derivadas úteis para EM, NEM e eixo técnico-profissional;
- preservar a utilidade do pipeline para além da pergunta principal do estudo de caso.

## Decisões gerais

| Decisão                                                   | Motivo                                                                                                                                                    |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Manter `serving` como nome da camada final no projeto dbt | No repositório, `serving` é a camada publicada/consumível. Conceitualmente ela equivale à `gold`.                                                         |
| Materializar `intermediate` prioritariamente como `table` | Mantém boa performance no consumo, mas alguns modelos grandes e compatibilizados foram mantidos como `view` para evitar inconsistências de materialização observadas no DuckDB. |
| Criar um painel escola/ano 2019-2025 compatibilizado      | Esse é o núcleo para análises temporais de EB, EM e técnico sem reescrever joins a cada estudo.                                                           |
| Separar histórico técnico em outro modelo escola/ano      | O técnico tem grão próprio por curso/área; agregá-lo separadamente preserva rastreabilidade.                                                              |
| Criar um painel município/ano completo 2019-2025          | Permite leitura longitudinal do NEM, mesmo quando uma fonte específica não cobre todos os anos.                                                           |
| Repetir o contexto do IBGE 2022 ao longo do painel        | O IBGE municipal e a alfabetização são estruturais e não anuais; repetir com `ano_base_ibge_contexto = 2022` é preferível a perder contexto fora de 2022. |
| Expandir o SAEB para o ano da edição e o ano seguinte    | Como o SAEB é bienal e serve de referência ao ciclo seguinte, 2019 alimenta 2020, 2021 alimenta 2022 e 2023 alimenta 2024.                                |
| Classificar períodos do NEM já na intermediate            | `pre_nem`, `implementacao_nem` e `pos_nem` são recortes estruturais da análise, úteis em várias saídas.                                                   |

## Compatibilização entre Censo Escolar 2019-2024 e 2025

O principal ponto metodológico da `intermediate` é que 2025 não é continuação direta da tabela larga de 2019-2024. Em 2025, o Censo foi quebrado em tabelas temáticas de escola, matrícula, turma, docente, gestor e curso técnico.

Por isso, a compatibilização foi feita em duas frentes:

1. `int_censo_escola_ano_2019_2025`
   - une o histórico 2019-2024 com a reconstrução escola/ano de 2025;
   - preserva colunas históricas quando existem;
   - adiciona colunas específicas de 2025 sem forçar falsa comparabilidade;
   - cria variáveis `*_compat` quando existe uma leitura razoavelmente comparável entre anos.

2. `int_censo_curso_tecnico_escola_ano_2023_2025`
   - agrega o histórico técnico 2023-2025 no grão escola/ano;
   - mantém a informação técnica separada da base escolar geral;
   - permite enriquecer EM/NEM com técnico sem colapsar o grão original do curso.

### Materialização adotada nos compatibilizados principais

Durante a validação, houve um comportamento inconsistente do DuckDB em parte das tabelas intermediárias materializadas como `table`: a SQL compilada retornava cobertura nacional, mas a relação materializada persistia com cobertura reduzida em alguns agregados.

Para evitar esse risco na camada analítica, os modelos compatibilizados centrais foram mantidos como `view`:

- `int_censo_escola_ano_2019_2025`
- `int_municipio_ano_oferta_educacional`
- `int_municipio_ano_nem`
- `int_municipio_ano_tecnico`

Com isso, a `intermediate` preserva a lógica validada da query e evita publicar uma tabela física inconsistente. Os demais modelos podem continuar como `table` quando não apresentarem esse problema.

### Variáveis compatibilizadas

As seguintes variáveis foram tratadas como comparáveis entre 2019 e 2025:

- `in_med_compat`
- `in_prof_tec_compat`
- `in_em_tempo_integral_compat`
- `qt_mat_med_compat`
- `qt_mat_med_int_compat`
- `qt_mat_prof_tec_compat`
- `qt_tur_med_compat`
- `qt_tur_med_int_compat`
- `qt_tur_prof_tec_compat`
- `qt_doc_med_compat`
- `qt_doc_prof_tec_compat`

Essas colunas servem para análise temporal contínua. Já colunas como itinerários, aprofundamentos e vários detalhamentos de 2025 foram preservadas, mas não foram tratadas como série histórica completa porque não existe equivalente estável em todos os anos anteriores.

## Camadas municipais construídas

### `int_municipio_ano_contexto`

Painel estrutural 2019-2025 com:

- diretório municipal;
- PIB anual quando disponível;
- contexto IBGE 2022 reaplicado ao painel;
- agregação municipal da alfabetização detalhada.

Essa tabela funciona como espinha dorsal para cruzar oferta educacional, desempenho e contexto socioeconômico.

### `int_municipio_ano_oferta_educacional`

Agrega o painel escola/ano compatibilizado e entrega:

- quantidade de escolas por município;
- recortes por dependência administrativa e localização;
- oferta de EB, EM, EJA e técnico;
- infraestrutura escolar;
- matrículas, docentes, turmas e gestores;
- proporções e razões estruturais.

### `int_municipio_ano_nem`

Foca especificamente no ensino médio e nos sinais do NEM:

- matrículas de EM;
- tempo integral;
- aprofundamentos e itinerários;
- articulação técnico-profissional;
- turmas, docentes e gestão associadas ao EM.

### `int_municipio_ano_tecnico`

Resume o histórico técnico no nível municipal:

- escolas com oferta técnica;
- quantidade de cursos e áreas;
- matrículas por modalidade técnica;
- flags de disponibilidade histórica da fonte.

### `int_municipio_ano_saeb`

Cria um recorte canônico do SAEB municipal:

- dependência administrativa: `Total - Federal, Estadual e Municipal`;
- localização: `Total`.

Essa escolha privilegia comparabilidade com análise de política pública. O recorte privado ou outros totais ainda permanecem acessíveis na staging para análises específicas.

### `int_municipio_ano_saeb_ciclo`

Expande o recorte canônico do SAEB para uso no ciclo anual:

- mantém o ano original da edição em `ano_saeb`;
- replica o resultado no ano seguinte como referência de ciclo;
- permite que 2020, 2022 e 2024 tenham resultado vigente sem perder a rastreabilidade da edição.

### `int_municipio_ano_painel_educacional`

É a principal saída da `intermediate` para a futura `serving/gold`. Ela une:

- contexto;
- oferta educacional;
- sinais do NEM;
- histórico técnico;
- SAEB vigente no ciclo quando disponível.

## Recortes temporais do NEM

Os períodos foram definidos assim:

- `pre_nem`: 2019-2021
- `implementacao_nem`: 2022-2023
- `pos_nem`: 2024-2025

Esse recorte já foi introduzido na `intermediate` porque ele é estrutural e pode ser reutilizado em:

- tabelas finais da disciplina;
- notebooks analíticos;
- estudos comparativos por período;
- métricas de variação agregadas na `serving`.

### Limitação com SAEB

O SAEB observado só existe no pipeline atual para 2019, 2021 e 2023. Na `intermediate`, esses resultados foram expandidos para o ciclo vigente:

- SAEB 2019 alimenta 2019 e 2020;
- SAEB 2021 alimenta 2021 e 2022;
- SAEB 2023 alimenta 2023 e 2024.

Com isso:

- o painel municipal fica coberto com SAEB para 2019, 2020, 2021, 2022, 2023 e 2024;
- 2025 passa a ser o único ano sem resultado SAEB vigente no estado atual do projeto;
- a rastreabilidade é preservada por meio de `ano_saeb_referencia`, distinguindo ano analítico e ano da edição.

Isso melhora a análise temporal sem inventar nova observação de desempenho. A `serving/gold` ainda deve deixar explícito quando a análise usa SAEB observado e quando usa SAEB vigente no ciclo.

## Status de validação

A camada `intermediate` foi validada com `dbt test` e com testes específicos de cobertura e reconciliação:

- cobertura municipal esperada em `int_censo_escola_ano_2019_2025`;
- cobertura municipal esperada nos agregados municipais derivados do Censo e do painel;
- reconciliação entre agregação escola/ano e agregação município/ano para matrículas, turmas, docentes e técnico.

Na prática, isso significa que a `intermediate` já está estável o suficiente para servir de base à `serving`, sem depender do notebook de inspeção para a validação principal.

## O que fica para a serving/gold

A `intermediate` não deve encerrar toda a interpretação final. A camada `serving` deve ficar responsável por:

- datasets finais orientados a consumo;
- recortes finais do estudo de caso;
- indicadores consolidados para publicação;
- dicionário final orientado a usuário e não só a pipeline.

Em termos conceituais:

- `staging`: padroniza;
- `intermediate`: compatibiliza e agrega;
- `serving`: publica o produto final analítico.

No seu projeto, `serving` pode ser entendida como a `gold`.
