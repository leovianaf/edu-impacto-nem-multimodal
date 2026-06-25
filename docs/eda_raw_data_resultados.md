# Resultados do EDA da camada raw

Este documento resume o que o notebook `notebooks/01_eda_raw_data.ipynb` mostra sobre os arquivos brutos do projeto e quais decisões ele sustenta para a camada `staging` do dbt.

## O que o notebook avalia

O notebook foi montado para responder perguntas de engenharia de dados antes da modelagem:

- quais arquivos existem em `data/raw/`;
- qual família, ano, encoding, delimitador, tamanho, número de linhas e número de colunas cada arquivo possui;
- quais colunas aparecem, somem ou mudam entre anos;
- quais campos podem funcionar como chaves de integração;
- onde existem nulos, cardinalidade alta ou valores categóricos esperados;
- quais granularidades e testes precisam ser levados para o dbt.

## Principais resultados observados

A camada raw contém bases do Censo Escolar, SAEB e IBGE. No inventário executado pelo notebook aparecem:

- Censo Escolar 2019 a 2024 em arquivos anuais de microdados de educação básica;
- suplementos de cursos técnicos em 2023 e 2024;
- Censo Escolar 2025 separado em tabelas temáticas, como escola, matrícula, turma, docente, gestor escolar e curso técnico;
- SAEB 2019, 2021 e 2023 em resultados agregados por município;
- base de alfabetização do Censo IBGE 2022.

Os arquivos usam majoritariamente CSV compactado em `.csv.gz` e delimitador `;`. Nas bases do Censo Escolar, o encoding alterna entre `cp1252` e `utf-8-sig`; no SAEB e no arquivo do IBGE 2022 predomina `utf-8-sig`. O notebook detecta essas características automaticamente, o que reduz risco de erro manual na leitura.

## Volume e schema

Os microdados do Censo Escolar são as bases mais largas e volumosas. O Censo Escolar 2024, por exemplo, aparece com 215.545 linhas e 426 colunas. O Censo 2023 aparece com 217.625 linhas e 408 colunas. Entre 2019 e 2024 há crescimento e mudança no conjunto de colunas: os arquivos têm 370 colunas entre 2019 e 2021, 385 em 2022, 408 em 2023 e 426 em 2024. Portanto, a staging não deve assumir que todos os anos têm exatamente o mesmo layout.

O SAEB aparece com 68.742 linhas em 2019, 64.693 em 2021 e 69.053 em 2023. A estrutura do SAEB é mais adequada para integração municipal porque já traz `CO_MUNICIPIO`, UF, dependência administrativa, localização, médias e distribuições por níveis.

As colunas `MEDIA_*` do SAEB não são notas de 0 a 10. Elas representam médias de proficiência na escala do SAEB, uma escala padronizada usada para comparar desempenho entre etapas, disciplinas e recortes territoriais. Por isso, valores como 206, 250 ou 267 não indicam "20,6", "25,0" ou "26,7" em uma prova. Eles indicam pontos na escala de proficiência.

No arquivo de 2023, o perfil numérico calculado no notebook mostra:

- `MEDIA_5_LP`: média 206,23, mínimo 122,86 e máximo 329,95;
- `MEDIA_5_MT`: média 218,32, mínimo 124,27 e máximo 356,85;
- `MEDIA_9_LP`: média 250,82, mínimo 170,45 e máximo 362,02;
- `MEDIA_9_MT`: média 250,63, mínimo 172,34 e máximo 404,89;
- `MEDIA_12_LP`: média 267,95, mínimo 189,70 e máximo 353,25;
- `MEDIA_12_MT`: média 266,24, mínimo 203,87 e máximo 414,56.

Esses campos devem ser tratados como `proficiência` ou `media_saeb`, e não como `nota_prova`. Uma eventual conversão para escala 0 a 10 seria uma métrica derivada e comunicacional, não uma correção do dado bruto.

As colunas `nivel_*` do SAEB indicam o percentual de alunos em cada faixa oficial de proficiência. Elas complementam as médias porque mostram a distribuição do desempenho: duas redes podem ter média parecida, mas uma pode concentrar mais alunos nos níveis baixos enquanto outra tem mais alunos nos níveis intermediários ou altos.

Para o ensino médio, os sufixos mais importantes são:

- `LP12` e `MT12`: 3ª/4ª série do ensino médio tradicional;
- `LP13` e `MT13`: 3ª/4ª série do ensino médio integrado;
- `LP14` e `MT14`: 3ª/4ª série do ensino médio tradicional ou integrado, de forma agregada.

As faixas de Língua Portuguesa no ensino médio (`nivel_*_LP12`, `nivel_*_LP13` e `nivel_*_LP14`) vão de `nivel_0` a `nivel_8`:

- `nivel_0`: desempenho menor que 225;
- `nivel_1`: desempenho maior ou igual a 225 e menor que 250;
- `nivel_2`: desempenho maior ou igual a 250 e menor que 275;
- `nivel_3`: desempenho maior ou igual a 275 e menor que 300;
- `nivel_4`: desempenho maior ou igual a 300 e menor que 325;
- `nivel_5`: desempenho maior ou igual a 325 e menor que 350;
- `nivel_6`: desempenho maior ou igual a 350 e menor que 375;
- `nivel_7`: desempenho maior ou igual a 375 e menor que 400;
- `nivel_8`: desempenho maior ou igual a 400.

As faixas de Matemática no ensino médio (`nivel_*_MT12`, `nivel_*_MT13` e `nivel_*_MT14`) vão de `nivel_0` a `nivel_10`:

- `nivel_0`: desempenho menor que 225;
- `nivel_1`: desempenho maior ou igual a 225 e menor que 250;
- `nivel_2`: desempenho maior ou igual a 250 e menor que 275;
- `nivel_3`: desempenho maior ou igual a 275 e menor que 300;
- `nivel_4`: desempenho maior ou igual a 300 e menor que 325;
- `nivel_5`: desempenho maior ou igual a 325 e menor que 350;
- `nivel_6`: desempenho maior ou igual a 350 e menor que 375;
- `nivel_7`: desempenho maior ou igual a 375 e menor que 400;
- `nivel_8`: desempenho maior ou igual a 400 e menor que 425;
- `nivel_9`: desempenho maior ou igual a 425 e menor que 450;
- `nivel_10`: desempenho maior ou igual a 450.

Portanto, a staging do SAEB deve preservar `MEDIA_*` e `nivel_*`. Na análise final, as médias e níveis com sufixos `12`, `13` e `14` devem ser priorizados para responder perguntas relacionadas ao Novo Ensino Médio, enquanto 5º e 9º ano podem funcionar como contexto da trajetória educacional do município.

O Censo Escolar 2025 exige atenção especial: ele não segue o mesmo desenho de arquivo único largo dos anos anteriores. A modelagem deve respeitar as tabelas temáticas e só integrar depois de entender a granularidade de cada uma. O notebook encontrou 214.192 linhas na tabela de escola, 178.766 na de matrícula, 178.772 nas de turma e docente, 180.540 na de gestor escolar e 32.136 na de curso técnico.

A base IBGE 2022 de alfabetização tem 779.800 linhas, 6 colunas e granularidade por município, raça/cor, sexo, grupo de idade e condição de alfabetização.

## Qualidade e chaves

O perfil de nulos e cardinalidade mostra que campos centrais de identificação não têm ausência nos recortes avaliados:

- `ANO_SAEB`, `CO_UF`, `CO_MUNICIPIO`, `DEPENDENCIA_ADM` e `LOCALIZACAO` no SAEB 2023;
- `NU_ANO_CENSO`, `CO_UF`, `SG_UF`, `CO_MUNICIPIO`, `CO_ENTIDADE`, `TP_DEPENDENCIA` e `TP_LOCALIZACAO` no Censo Escolar 2024.

As chaves candidatas testadas não apresentaram duplicidade:

- SAEB 2023: `ANO_SAEB + CO_MUNICIPIO + DEPENDENCIA_ADM + LOCALIZACAO`;
- Censo Escolar 2024: `NU_ANO_CENSO + CO_ENTIDADE`.

Isso indica que essas combinações podem virar testes `unique` compostos no dbt.

Para o Censo Escolar 2025, `NU_ANO_CENSO + CO_ENTIDADE` também não apresentou duplicidade nas tabelas de escola, matrícula, turma, docente e gestor escolar. A exceção foi `Tabela_Curso_Tecnico_2025`, em que essa combinação teve 6.923 chaves duplicadas e 27.033 linhas dentro de chaves duplicadas. Essa tabela precisa de uma chave composta mais específica, provavelmente incluindo campos do curso técnico.

O notebook também validou códigos territoriais contra a seed municipal. `CO_UF`, `SG_UF`, `CO_MUNICIPIO` e `id_municipio` tiveram 100% de compatibilidade nos recortes avaliados do SAEB 2023, Censo Escolar 2024, Censo Escolar 2025 e IBGE 2022. Já `CO_ENTIDADE` aparece como identificador aceito pelo dicionário do Censo Escolar, mas sem referência externa na seed municipal usada no teste.

## Integração municipal

O notebook compara `CO_MUNICIPIO` entre SAEB 2023 e Censo Escolar 2024. Em ambos os casos, o código municipal tem 7 caracteres, com mínimo `1100015` e máximo `5300108`.

A cobertura difere:

- SAEB 2023: 5.557 municípios;
- Censo Escolar 2024: 5.570 municípios;
- Censo Escolar 2025, tabela de escola: 5.571 municípios.

Portanto, o join municipal é viável, mas a diferença de cobertura deve ser monitorada e documentada nas camadas intermediárias.

## Nulos e interpretação

Os nulos observados parecem estruturais, não necessariamente erros de qualidade.

No SAEB 2023, médias como `MEDIA_5_LP`, `MEDIA_5_MT`, `MEDIA_9_LP`, `MEDIA_9_MT`, `MEDIA_12_LP` e `MEDIA_12_MT` têm ausência em parte das linhas. O notebook encontrou 16,42% de nulos em `MEDIA_5_LP` e `MEDIA_5_MT`, 17,76% em `MEDIA_9_LP` e `MEDIA_9_MT`, e 36,61% em `MEDIA_12_LP` e `MEDIA_12_MT`. Isso é esperado quando determinado recorte de município, dependência, localização ou etapa não possui resultado divulgado.

No Censo Escolar 2024, campos de mediação e matrículas do ensino médio também têm ausência relevante. As variáveis de mediação avaliadas têm cerca de 16,00% de nulos, e as variáveis `QT_MAT_MED`, `QT_MAT_MED_PROP`, `QT_MAT_MED_INT` e `QT_MAT_MED_NM` têm cerca de 16,82% de nulos. Isso é compatível com escolas que não ofertam ensino médio ou não se enquadram na variável analisada.

Nas variáveis de matrícula do ensino médio, a média também precisa ser interpretada com cuidado. Em 2024, `QT_MAT_MED` tem média 43,45, mas mediana 0 e percentil 75 igual a 0. Em 2025, `QT_MAT_MED` tem média 41,23, mediana 0 e percentil 75 igual a 0. A média fica maior porque poucas escolas concentram muitas matrículas, enquanto a maioria das linhas tem valor zero. Assim, para essas contagens, mediana, percentis e máximos são tão importantes quanto a média.

Na base IBGE 2022, `populacao` tem 32,07% de nulos. Como a base cruza município, raça/cor, sexo, faixa etária e alfabetização, esses nulos tendem a indicar combinações sem população divulgada ou aplicável, e não necessariamente erro de extração.

A recomendação é preservar esses nulos na staging. Qualquer imputação, filtro analítico ou agregação deve acontecer em camadas posteriores.

## Como ficaria o antes e depois

Com as bases disponíveis, o projeto consegue montar uma análise antes/depois em nível observacional. A comparação mais segura é municipal, porque o SAEB usado no projeto está em resultados agregados por município e pode ser integrado com Censo Escolar, PIB municipal e indicadores do IBGE por `id_municipio`.

O recorte sugerido é:

- **Antes do NEM:** usar SAEB 2019 como principal linha de base pré-implementação e Censo Escolar 2019, 2020 e 2021 para descrever a estrutura escolar anterior ou em transição.
- **Transição:** tratar 2021 e 2022 com cuidado, porque 2021 ainda carrega efeitos da pandemia e 2022 representa um período de implementação desigual entre redes.
- **Depois do NEM:** usar SAEB 2023 como primeiro resultado pós-implementação mais consolidada e Censo Escolar 2023, 2024 e 2025 para observar mudanças na oferta, nas matrículas e na estrutura do ensino médio.

Essa análise deve ser comunicada como correlação ou associação, não como prova causal direta. A base final poderá indicar se municípios ou redes com maior sinal de implementação do NEM apresentaram maior, menor ou nenhuma variação associada nas proficiências do SAEB.

Para viabilizar essa leitura, a camada final precisa construir:

- uma unidade de análise clara, preferencialmente `id_municipio + ano + recortes` para o primeiro ciclo;
- indicadores de desempenho comparáveis no tempo, como médias de proficiência em Língua Portuguesa e Matemática;
- indicadores de variação, como `delta_media_saeb_2023_2019`;
- proxies de implementação do NEM a partir do Censo Escolar, como matrículas no ensino médio, ensino médio integral, oferta técnica/profissional e mudanças na oferta;
- indicadores socioeconômicos municipais, como PIB, população e alfabetização;
- flags de período, como `pre_nem`, `transicao` e `pos_nem`;
- documentação das limitações, principalmente pandemia, granularidade municipal do SAEB, ausência de causalidade e diferenças de implementação entre redes.

## TODO para seguir para staging

- [X] Definir a unidade inicial da análise antes/depois: município, escola ou rede. Para reduzir risco, começar por município.
- [X] Definir oficialmente os períodos analíticos: `pre_nem`, `transicao` e `pos_nem`.
- [X] Escolher quais colunas do SAEB entram na staging como indicadores de proficiência e quais recortes serão preservados.
- [X] Escolher quais variáveis do Censo Escolar serão usadas como proxies de implementação do NEM.
- [X] Validar a granularidade de cada base antes do join, especialmente Censo Escolar 2025 e cursos técnicos.
- [X] Criar staging do SAEB municipal preservando a escala original de proficiência.
- [X] Criar staging do Censo Escolar 2019-2024 mantendo granularidade escola/ano.
- [X] Criar staging do Censo Escolar 2025 separando escola, matrícula e curso técnico conforme a granularidade.
- [X] Criar staging do PIB municipal validando cobertura, anos disponíveis, separador, tipos numéricos e relacionamento com `id_municipio`.
- [X] Criar staging do IBGE Censo municipal preservando indicadores demográficos e taxa de alfabetização.
- [X] Criar staging do IBGE de alfabetização detalhada preservando nulos estruturais e categorias originais.
- [X] Criar staging do diretório municipal como dimensão territorial e referência para testes.
- [X] Padronizar chaves territoriais como texto, principalmente `id_municipio`, `co_municipio`, `co_uf` e `sg_uf`.
- [X] Classificar nulos entre estruturais e problemáticos antes de qualquer imputação.
- [X] Definir testes dbt mínimos: `not_null`, `unique` composto, `accepted_values`, faixas numéricas e relacionamento com a seed municipal.
- [X] Documentar regras de qualidade: completude das chaves, validade dos domínios, unicidade por granularidade, compatibilidade territorial, coerência numérica e rastreabilidade da fonte.
- [ ] Depois da staging, criar uma camada intermediária municipal com indicadores comparáveis por ano.
- [ ] Na camada final, calcular deltas antes/depois e cruzar desempenho SAEB com proxies do NEM e indicadores socioeconômicos.

## Decisões para staging

Modelos candidatos:

- `stg_saeb_resultados_municipios`;
- `stg_censo_escolar_escolas`;
- `stg_censo_escolar_cursos_tecnicos`;
- `stg_censo_escolar_2025_*` para tabelas temáticas;
- `stg_ibge_alfabetizacao_municipio`;
- `stg_ibge_pib_municipio`.

Padronizações recomendadas:

- converter nomes para `snake_case`;
- padronizar `ANO_SAEB` e `NU_ANO_CENSO` como `ano`;
- padronizar `CO_MUNICIPIO` como `id_municipio`;
- padronizar `CO_ENTIDADE` como `id_escola`;
- preservar códigos territoriais como texto;
- converter médias de proficiência do SAEB e indicadores numéricos para decimal, preservando a escala original do SAEB;
- converter contagens para inteiro;
- tratar flags `IN_*` de forma consistente como boolean ou inteiro pequeno.

Uma transformação para escala 0 a 10, se for desejada para visualização ou comparação comunicacional, deve ser uma métrica derivada em camada intermediária ou serving, nunca uma substituição do valor bruto na staging.

Testes dbt prioritários:

- `not_null` nas chaves;
- `unique` composto conforme a granularidade de cada staging;
- `accepted_values` para UF, dependência, localização e flags;
- faixas válidas para médias SAEB;
- relacionamento de `id_municipio` com a seed municipal.

## Enriquecimentos adicionados ao notebook

O notebook já tinha boas verificações estruturais, mas faltava uma camada visual e estatística. Foram adicionadas células para:

- estatísticas descritivas de variáveis numéricas;
- histogramas de médias SAEB;
- gráfico de barras para frequências categóricas;
- perfil numérico de matrículas do ensino médio no Censo Escolar;
- distribuição de `QT_MAT_MED` no Censo Escolar 2024.

Esses gráficos ajudam a encontrar assimetrias, valores extremos e concentração por categoria antes da criação das regras finais de staging.

## Conclusão

O EDA mostrou que a camada raw estava apta para a modelagem staging, desde que a modelagem tratasse explicitamente as diferenças de layout entre anos, preservasse nulos estruturais e mantivesse testes de integridade para as chaves de integração. A staging foi criada seguindo esse caminho: SAEB municipal, Censo Escolar em granularidade escola/ano, Censo Escolar 2025 separado por tabelas temáticas, PIB municipal em formato longo, IBGE municipal, alfabetização detalhada e diretório municipal. As decisões finais da staging estão documentadas em `docs/staging_decisoes.md`.
