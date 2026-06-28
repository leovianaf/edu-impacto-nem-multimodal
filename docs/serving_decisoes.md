# Documentação da serving e decisões de modelagem

A `serving` é a camada final publicada do projeto. Ela é derivada da `intermediate` e existe para entregar datasets prontos para análise, publicação e exportação multimodal.

## Princípios

- publicar tabelas em grãos estáveis e fáceis de consumir;
- evitar reintroduzir a complexidade de staging e intermediate;
- manter o foco em EM/NEM, sem perder o eixo técnico;
- carregar contexto municipal e SAEB nos grãos que precisam disso;
- espelhar a `serving` no MongoDB e construir relações no Neo4j a partir dos mesmos datasets.

## Tabelas publicadas

- `srv_municipio_ano_painel_educacional`
- `srv_municipio_ano_nem`
- `srv_municipio_ano_tecnico`
- `srv_escola_ano_em`
- `srv_escola_ano_tecnico`
- `srv_escola_ano_em_tecnico`

## Limitação importante

A pipeline atual não contém uma fonte explícita de abandono/reprovação escolar. Isso significa que esses indicadores não devem ser inventados na serving. Se forem necessários, a fonte correspondente precisa entrar antes na staging.
