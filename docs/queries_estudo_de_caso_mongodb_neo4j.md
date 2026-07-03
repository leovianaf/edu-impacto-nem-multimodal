# Análises válidas da serving no MongoDB e Neo4j via queries

## Escopo

As consultas abaixo respondem as perguntas de pesquisa com indicadores que possuem cobertura real. A unidade do SAEB e o municipio, por isso, dados escolares sao agregados por municipio antes de serem relacionados ao desempenho.

Indicadores validos:

- expansao das matriculas de EM integral entre 2019 e 2023;
- proporcao de escolas regulares de EM com tempo integral, educacao profissional e infraestrutura;
- coexistencia de EM e oferta tecnica na mesma escola em 2023;
- PIB per capita e alfabetizacao como contexto socioeconomico.

Nao usar `prop_mat_em_tecnico_profissional` nem `prop_escolas_itinerario_tecn_prof` antes de 2025. Nao vamos interpretar associações como efeito causal do NEM.

## Pergunta de pesquisa e alcance da análise

> Existe correlação entre a implementação do NEM e a variação de desempenho acadêmico observada no SAEB?

A serving não contém uma medida normativa única de implementação do NEM. Por isso, o estudo operacionaliza a pergunta com proxies que possuem cobertura temporal válida: expansão do EM integral, mudanças na estrutura das escolas de EM e coexistência de EM com educação técnica. As consultas permitem estimar associações municipais e descrever evoluções, mas não identificar impacto causal.

## MongoDB Compass

### M1. Evolucao do EM integral e do SAEB, 2019-2023

Colecao: `srv_municipio_ano_painel_educacional`

Arquivo: `mongodb_m1_painel_em_integral_saeb_2019_2023.csv`

```json
[
  {
    "$match": {
      "ano": { "$in": [2019, 2023] },
      "in_ano_edicao_saeb": 1,
      "media_12_lp_mt": { "$ne": null },
      "qt_mat_med": { "$gt": 0 }
    }
  },
  {
    "$group": {
      "_id": "$id_municipio",
      "nome_municipio": { "$first": "$nome_municipio" },
      "sigla_uf": { "$first": "$sigla_uf" },
      "nome_regiao": { "$first": "$nome_regiao" },
      "media_saeb_2019": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2019] }, "$media_12_lp_mt", null]
        }
      },
      "media_saeb_2023": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2023] }, "$media_12_lp_mt", null]
        }
      },
      "prop_mat_em_integral_2019": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2019] }, "$prop_mat_em_integral", null]
        }
      },
      "prop_mat_em_integral_2023": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2023] }, "$prop_mat_em_integral", null]
        }
      },
      "pib_per_capita_2023": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2023] }, "$pib_per_capita", null]
        }
      },
      "taxa_alfabetizacao_2023": {
        "$max": {
          "$cond": [{ "$eq": ["$ano", 2023] }, "$taxa_alfabetizacao", null]
        }
      }
    }
  },
  {
    "$match": {
      "media_saeb_2019": { "$ne": null },
      "media_saeb_2023": { "$ne": null },
      "prop_mat_em_integral_2019": { "$ne": null },
      "prop_mat_em_integral_2023": { "$ne": null }
    }
  },
  {
    "$project": {
      "_id": 0,
      "id_municipio": "$_id",
      "nome_municipio": 1,
      "sigla_uf": 1,
      "nome_regiao": 1,
      "media_saeb_2019": 1,
      "media_saeb_2023": 1,
      "delta_saeb_2019_2023": {
        "$subtract": ["$media_saeb_2023", "$media_saeb_2019"]
      },
      "prop_mat_em_integral_2019": 1,
      "prop_mat_em_integral_2023": 1,
      "delta_prop_mat_em_integral_2019_2023": {
        "$subtract": [
          "$prop_mat_em_integral_2023",
          "$prop_mat_em_integral_2019"
        ]
      },
      "pib_per_capita_2023": 1,
      "taxa_alfabetizacao_2023": 1
    }
  },
  { "$sort": { "id_municipio": 1 } }
]
```

### M2. Mudancas na estrutura das escolas regulares de EM

Colecao: `srv_escola_ano_em`

Arquivo: `mongodb_m2_estrutura_escolas_em_2019_2023.csv`

```json
[
  {
    "$match": {
      "ano": { "$in": [2019, 2023] },
      "in_med_padronizado": 1,
      "media_12_lp_mt": { "$ne": null }
    }
  },
  {
    "$group": {
      "_id": { "id_municipio": "$id_municipio", "ano": "$ano" },
      "nome_municipio": { "$first": "$nome_municipio" },
      "sigla_uf": { "$first": "$sigla_uf" },
      "nome_regiao": { "$first": "$nome_regiao" },
      "escolas_em": { "$sum": 1 },
      "escolas_em_integral": {
        "$sum": {
          "$cond": [
            { "$gt": [{ "$ifNull": ["$prop_mat_em_integral_escola", 0] }, 0] },
            1,
            0
          ]
        }
      },
      "escolas_em_prof_tec": {
        "$sum": { "$cond": [{ "$eq": ["$in_prof_tec", 1] }, 1, 0] }
      },
      "escolas_internet_aprendizagem": {
        "$sum": { "$cond": [{ "$eq": ["$in_internet_aprendizagem", 1] }, 1, 0] }
      },
      "escolas_biblioteca": {
        "$sum": { "$cond": [{ "$eq": ["$in_biblioteca", 1] }, 1, 0] }
      },
      "escolas_lab_ciencias": {
        "$sum": { "$cond": [{ "$eq": ["$in_laboratorio_ciencias", 1] }, 1, 0] }
      },
      "media_saeb": { "$first": "$media_12_lp_mt" }
    }
  },
  {
    "$set": {
      "prop_escolas_em_integral": {
        "$divide": ["$escolas_em_integral", "$escolas_em"]
      },
      "prop_escolas_em_prof_tec": {
        "$divide": ["$escolas_em_prof_tec", "$escolas_em"]
      },
      "prop_escolas_internet_aprendizagem": {
        "$divide": ["$escolas_internet_aprendizagem", "$escolas_em"]
      },
      "prop_escolas_biblioteca": {
        "$divide": ["$escolas_biblioteca", "$escolas_em"]
      },
      "prop_escolas_lab_ciencias": {
        "$divide": ["$escolas_lab_ciencias", "$escolas_em"]
      }
    }
  },
  {
    "$group": {
      "_id": "$_id.id_municipio",
      "nome_municipio": { "$first": "$nome_municipio" },
      "sigla_uf": { "$first": "$sigla_uf" },
      "nome_regiao": { "$first": "$nome_regiao" },
      "saeb_2019": {
        "$max": {
          "$cond": [{ "$eq": ["$_id.ano", 2019] }, "$media_saeb", null]
        }
      },
      "saeb_2023": {
        "$max": {
          "$cond": [{ "$eq": ["$_id.ano", 2023] }, "$media_saeb", null]
        }
      },
      "integral_2019": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2019] },
            "$prop_escolas_em_integral",
            null
          ]
        }
      },
      "integral_2023": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2023] },
            "$prop_escolas_em_integral",
            null
          ]
        }
      },
      "prof_tec_2019": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2019] },
            "$prop_escolas_em_prof_tec",
            null
          ]
        }
      },
      "prof_tec_2023": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2023] },
            "$prop_escolas_em_prof_tec",
            null
          ]
        }
      },
      "internet_2019": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2019] },
            "$prop_escolas_internet_aprendizagem",
            null
          ]
        }
      },
      "internet_2023": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2023] },
            "$prop_escolas_internet_aprendizagem",
            null
          ]
        }
      },
      "biblioteca_2019": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2019] },
            "$prop_escolas_biblioteca",
            null
          ]
        }
      },
      "biblioteca_2023": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2023] },
            "$prop_escolas_biblioteca",
            null
          ]
        }
      },
      "lab_ciencias_2019": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2019] },
            "$prop_escolas_lab_ciencias",
            null
          ]
        }
      },
      "lab_ciencias_2023": {
        "$max": {
          "$cond": [
            { "$eq": ["$_id.ano", 2023] },
            "$prop_escolas_lab_ciencias",
            null
          ]
        }
      }
    }
  },
  { "$match": { "saeb_2019": { "$ne": null }, "saeb_2023": { "$ne": null } } },
  {
    "$project": {
      "_id": 0,
      "id_municipio": "$_id",
      "nome_municipio": 1,
      "sigla_uf": 1,
      "nome_regiao": 1,
      "delta_saeb_2019_2023": { "$subtract": ["$saeb_2023", "$saeb_2019"] },
      "delta_prop_escolas_integral": {
        "$subtract": ["$integral_2023", "$integral_2019"]
      },
      "delta_prop_escolas_prof_tec": {
        "$subtract": ["$prof_tec_2023", "$prof_tec_2019"]
      },
      "delta_prop_internet_aprendizagem": {
        "$subtract": ["$internet_2023", "$internet_2019"]
      },
      "delta_prop_biblioteca": {
        "$subtract": ["$biblioteca_2023", "$biblioteca_2019"]
      },
      "delta_prop_lab_ciencias": {
        "$subtract": ["$lab_ciencias_2023", "$lab_ciencias_2019"]
      }
    }
  },
  { "$sort": { "id_municipio": 1 } }
]
```

### M3. Coexistencia de EM e tecnico na mesma escola em 2023

Colecao: `srv_escola_ano_em_tecnico`

Arquivo: `mongodb_m3_em_tecnico_mesma_escola_2023.csv`

```json
[
  {
    "$match": {
      "ano": 2023,
      "in_med_padronizado": 1,
      "media_12_lp_mt": { "$ne": null }
    }
  },
  {
    "$group": {
      "_id": "$id_municipio",
      "nome_municipio": { "$first": "$nome_municipio" },
      "sigla_uf": { "$first": "$sigla_uf" },
      "nome_regiao": { "$first": "$nome_regiao" },
      "escolas_em": { "$sum": 1 },
      "escolas_em_com_tecnico": { "$sum": "$tem_em_e_tecnico_no_mesmo_ano" },
      "escolas_em_com_tecnico_nem": { "$sum": "$tem_em_e_tecnico_no_nem" },
      "media_saeb_2023": { "$first": "$media_12_lp_mt" },
      "pib": { "$first": "$pib" },
      "taxa_alfabetizacao": { "$first": "$taxa_alfabetizacao" }
    }
  },
  {
    "$project": {
      "_id": 0,
      "id_municipio": "$_id",
      "nome_municipio": 1,
      "sigla_uf": 1,
      "nome_regiao": 1,
      "escolas_em": 1,
      "escolas_em_com_tecnico": 1,
      "escolas_em_com_tecnico_nem": 1,
      "prop_escolas_em_com_tecnico": {
        "$divide": ["$escolas_em_com_tecnico", "$escolas_em"]
      },
      "prop_escolas_em_com_tecnico_nem": {
        "$divide": ["$escolas_em_com_tecnico_nem", "$escolas_em"]
      },
      "media_saeb_2023": 1,
      "pib": 1,
      "taxa_alfabetizacao": 1
    }
  },
  { "$sort": { "id_municipio": 1 } }
]
```

### M4. Contexto socioeconomico e SAEB em 2023

Colecao: `srv_municipio_ano_painel_educacional`

Arquivo: `mongodb_m4_contexto_socioeconomico_saeb_2023.csv`

```json
[
  {
    "$match": {
      "ano": 2023,
      "in_ano_edicao_saeb": 1,
      "media_12_lp_mt": { "$ne": null },
      "pib_per_capita": { "$ne": null },
      "taxa_alfabetizacao": { "$ne": null }
    }
  },
  {
    "$project": {
      "_id": 0,
      "id_municipio": 1,
      "nome_municipio": 1,
      "sigla_uf": 1,
      "nome_regiao": 1,
      "qt_escolas_em": 1,
      "qt_mat_med": 1,
      "prop_mat_em_integral": 1,
      "qt_mat_prof_tec": 1,
      "media_saeb_2023": "$media_12_lp_mt",
      "delta_saeb_2021_2023": "$delta_media_12_lp_mt",
      "pib_per_capita": 1,
      "taxa_alfabetizacao": 1
    }
  },
  { "$sort": { "id_municipio": 1 } }
]
```

## Neo4j Desktop

Antes de executar as queries, publique as novas propriedades no grafo:

```bash
python scripts/load_serving_nosql.py --target neo4j
```

### N1. Evolucao do EM integral e do SAEB, 2019-2023

Arquivo: `neo4j_n1_painel_em_integral_saeb_2019_2023.csv`

```cypher
MATCH (m:Municipio)-[r:PAINEL_MUNICIPAL]->(a:Ano)
WHERE a.ano IN [2019, 2023] AND r.in_ano_edicao_saeb = 1 AND r.media_12_lp_mt IS NOT NULL
WITH m,
  max(CASE WHEN a.ano = 2019 THEN r.media_12_lp_mt END) AS saeb_2019,
  max(CASE WHEN a.ano = 2023 THEN r.media_12_lp_mt END) AS saeb_2023,
  max(CASE WHEN a.ano = 2019 THEN r.prop_mat_em_integral END) AS integral_2019,
  max(CASE WHEN a.ano = 2023 THEN r.prop_mat_em_integral END) AS integral_2023,
  max(CASE WHEN a.ano = 2023 THEN r.pib_per_capita END) AS pib_per_capita_2023,
  max(CASE WHEN a.ano = 2023 THEN r.taxa_alfabetizacao END) AS taxa_alfabetizacao_2023
WHERE saeb_2019 IS NOT NULL AND saeb_2023 IS NOT NULL AND integral_2019 IS NOT NULL AND integral_2023 IS NOT NULL
RETURN m.id_municipio AS id_municipio, m.nome_municipio AS nome_municipio, m.sigla_uf AS sigla_uf, m.nome_regiao AS nome_regiao,
  saeb_2019, saeb_2023, saeb_2023 - saeb_2019 AS delta_saeb_2019_2023,
  integral_2019, integral_2023, integral_2023 - integral_2019 AS delta_prop_mat_em_integral_2019_2023,
  pib_per_capita_2023, taxa_alfabetizacao_2023
ORDER BY id_municipio;
```

### N2. Mudancas na estrutura das escolas regulares de EM

Arquivo: `neo4j_n2_estrutura_escolas_em_2019_2023.csv`

```cypher
MATCH (e:Escola)-[r:OFERTA_EM_TECNICO]->(a:Ano)
MATCH (m:Municipio {id_municipio: r.id_municipio})
WHERE a.ano IN [2019, 2023] AND r.in_med_padronizado = 1
WITH m, a.ano AS ano, count(e) AS escolas_em,
  avg(CASE WHEN r.prop_mat_em_integral_escola > 0 THEN 1.0 ELSE 0.0 END) AS prop_integral,
  avg(CASE WHEN r.in_prof_tec = 1 THEN 1.0 ELSE 0.0 END) AS prop_prof_tec,
  avg(CASE WHEN r.in_internet_aprendizagem = 1 THEN 1.0 ELSE 0.0 END) AS prop_internet,
  avg(CASE WHEN r.in_biblioteca = 1 THEN 1.0 ELSE 0.0 END) AS prop_biblioteca,
  avg(CASE WHEN r.in_laboratorio_ciencias = 1 THEN 1.0 ELSE 0.0 END) AS prop_lab_ciencias
WITH m,
  max(CASE WHEN ano = 2019 THEN escolas_em END) AS escolas_em_2019,
  max(CASE WHEN ano = 2023 THEN escolas_em END) AS escolas_em_2023,
  max(CASE WHEN ano = 2019 THEN prop_integral END) AS integral_2019, max(CASE WHEN ano = 2023 THEN prop_integral END) AS integral_2023,
  max(CASE WHEN ano = 2019 THEN prop_prof_tec END) AS prof_tec_2019, max(CASE WHEN ano = 2023 THEN prop_prof_tec END) AS prof_tec_2023,
  max(CASE WHEN ano = 2019 THEN prop_internet END) AS internet_2019, max(CASE WHEN ano = 2023 THEN prop_internet END) AS internet_2023,
  max(CASE WHEN ano = 2019 THEN prop_biblioteca END) AS biblioteca_2019, max(CASE WHEN ano = 2023 THEN prop_biblioteca END) AS biblioteca_2023,
  max(CASE WHEN ano = 2019 THEN prop_lab_ciencias END) AS lab_2019, max(CASE WHEN ano = 2023 THEN prop_lab_ciencias END) AS lab_2023
WHERE escolas_em_2019 IS NOT NULL AND escolas_em_2023 IS NOT NULL
MATCH (m)-[p19:PAINEL_MUNICIPAL]->(:Ano {ano: 2019}), (m)-[p23:PAINEL_MUNICIPAL]->(:Ano {ano: 2023})
WHERE p19.media_12_lp_mt IS NOT NULL AND p23.media_12_lp_mt IS NOT NULL
RETURN m.id_municipio AS id_municipio, m.nome_municipio AS nome_municipio, m.sigla_uf AS sigla_uf,
  escolas_em_2019, escolas_em_2023, p23.media_12_lp_mt-p19.media_12_lp_mt AS delta_saeb_2019_2023,
  integral_2023-integral_2019 AS delta_prop_integral,
  prof_tec_2023-prof_tec_2019 AS delta_prop_prof_tec, internet_2023-internet_2019 AS delta_prop_internet,
  biblioteca_2023-biblioteca_2019 AS delta_prop_biblioteca, lab_2023-lab_2019 AS delta_prop_lab_ciencias
ORDER BY id_municipio;
```

### N3. Coexistencia de EM e tecnico na mesma escola em 2023

Arquivo: `neo4j_n3_em_tecnico_mesma_escola_2023.csv`

```cypher
MATCH (e:Escola)-[r:OFERTA_EM_TECNICO]->(a:Ano {ano: 2023})
MATCH (m:Municipio {id_municipio: r.id_municipio})
WHERE r.in_med_padronizado = 1
WITH m, count(e) AS escolas_em,
  sum(r.tem_em_e_tecnico_no_mesmo_ano) AS escolas_em_com_tecnico,
  sum(r.tem_em_e_tecnico_no_nem) AS escolas_em_com_tecnico_nem
MATCH (m)-[p:PAINEL_MUNICIPAL]->(:Ano {ano: 2023})
WHERE p.media_12_lp_mt IS NOT NULL
RETURN m.id_municipio AS id_municipio, m.nome_municipio AS nome_municipio, m.sigla_uf AS sigla_uf,
  escolas_em, escolas_em_com_tecnico, escolas_em_com_tecnico_nem,
  escolas_em_com_tecnico * 1.0 / escolas_em AS prop_escolas_em_com_tecnico,
  escolas_em_com_tecnico_nem * 1.0 / escolas_em AS prop_escolas_em_com_tecnico_nem,
  p.media_12_lp_mt AS media_saeb_2023, p.pib_per_capita AS pib_per_capita, p.taxa_alfabetizacao AS taxa_alfabetizacao
ORDER BY id_municipio;
```

### N4. Contexto socioeconomico e SAEB em 2023

Arquivo: `neo4j_n4_contexto_socioeconomico_saeb_2023.csv`

```cypher
MATCH (m:Municipio)-[r:PAINEL_MUNICIPAL]->(a:Ano {ano: 2023})
WHERE r.in_ano_edicao_saeb = 1 AND r.media_12_lp_mt IS NOT NULL AND r.pib_per_capita IS NOT NULL AND r.taxa_alfabetizacao IS NOT NULL
RETURN m.id_municipio AS id_municipio, m.nome_municipio AS nome_municipio, m.sigla_uf AS sigla_uf, m.nome_regiao AS nome_regiao,
  r.qt_escolas_em AS qt_escolas_em, r.qt_mat_med AS qt_mat_med, r.prop_mat_em_integral AS prop_mat_em_integral,
  r.qt_mat_prof_tec AS qt_mat_prof_tec, r.media_12_lp_mt AS media_saeb_2023,
  r.delta_media_12_lp_mt AS delta_saeb_2021_2023, r.pib_per_capita AS pib_per_capita, r.taxa_alfabetizacao AS taxa_alfabetizacao
ORDER BY id_municipio;
```

## Arquivos esperados

| Pergunta                              | MongoDB                                            | Neo4j                                            |
| ------------------------------------- | -------------------------------------------------- | ------------------------------------------------ |
| NEM/tempo integral e SAEB             | `mongodb_m1_painel_em_integral_saeb_2019_2023.csv` | `neo4j_n1_painel_em_integral_saeb_2019_2023.csv` |
| Estrutura das escolas regulares de EM | `mongodb_m2_estrutura_escolas_em_2019_2023.csv`    | `neo4j_n2_estrutura_escolas_em_2019_2023.csv`    |
| EM e tecnico na mesma escola          | `mongodb_m3_em_tecnico_mesma_escola_2023.csv`      | `neo4j_n3_em_tecnico_mesma_escola_2023.csv`      |
| Contexto socioeconomico e SAEB        | `mongodb_m4_contexto_socioeconomico_saeb_2023.csv` | `neo4j_n4_contexto_socioeconomico_saeb_2023.csv` |

## Resultados obtidos com os exports atuais

Os quatro pares de exports do MongoDB e Neo4j apresentaram paridade de chaves e valores após a validação. Os resultados exploratórios foram:

- a proporção municipal média de matrículas de EM integral passou de 10,4% em 2019 para 24,7% em 2023;
- a média municipal do SAEB LP/MT passou de 272,18 para 267,93, uma redução média de 4,25 pontos;
- a correlação entre a mudança do EM integral e a mudança do SAEB foi praticamente nula: Pearson de 0,034 e Spearman de -0,001;
- as correlações de Spearman entre mudanças de infraestrutura/oferta escolar e mudança do SAEB ficaram entre aproximadamente -0,050 e 0,022, também muito fracas;
- municípios com EM e técnico na mesma escola tiveram média SAEB 2023 cerca de 1,60 ponto menor que os demais, diferença bruta e transversal que não deve ser interpretada como efeito da oferta técnica;
- alfabetização e PIB per capita apresentaram associações mais claras com o nível do SAEB 2023 (Spearman de 0,442 e 0,356), mas associações fracas com a variação 2021-2023 (-0,209 e -0,154).

### Conclusão do estudo de caso

Com os dados e proxies disponíveis, **não foi identificada associação municipal relevante entre a expansão do EM integral, as mudanças estruturais ligadas ao NEM e a variação do SAEB**. Foram observadas evoluções simultâneas, principalmente expansão do tempo integral e redução média do SAEB entre 2019 e 2023, mas a ocorrência conjunta no tempo não demonstra que uma causou a outra.

Portanto, a resposta adequada não é que o NEM comprovadamente não teve impacto, mas que **este desenho observacional e estes dados não fornecem evidência de um impacto associado mensurável no SAEB**. A pandemia, políticas estaduais, composição das redes, nível socioeconômico e ausência de uma medida completa de implementação impedem uma interpretação causal.

