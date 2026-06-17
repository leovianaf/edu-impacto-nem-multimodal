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

O EDA mostra que a camada raw está pronta para iniciar a modelagem staging, desde que a modelagem trate explicitamente as diferenças de layout entre anos, preserve nulos estruturais e mantenha testes de integridade para as chaves de integração. O caminho mais seguro é começar pelo SAEB municipal e pelo Censo Escolar em granularidade de escola/ano, usando `CO_MUNICIPIO` como eixo de integração com bases territoriais e socioeconômicas.
