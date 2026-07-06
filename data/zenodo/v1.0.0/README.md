# Dataset analítico sobre Ensino Médio, NEM, SAEB e educação técnica

Versão: 1.0.0

## Conteúdo

Este depósito contém a camada final (`serving`) do pipeline analítico. As
tabelas estão em Parquet com compressão ZSTD e preservam tipos e valores nulos.

| Tabela | Grão | Linhas | Colunas | Foco |
|---|---|---:|---:|---|
| `srv_municipio_ano_painel_educacional` | municipio/ano | 38,997 | 174 | Painel municipal integrado com NEM, SAEB, oferta educacional, educação técnica, PIB e alfabetização. |
| `srv_municipio_ano_nem` | municipio/ano | 38,997 | 96 | Recorte municipal para análises de Ensino Médio, NEM, estrutura, matrículas, SAEB e contexto. |
| `srv_municipio_ano_tecnico` | municipio/ano | 13,307 | 35 | Oferta, presença e intensidade da educação profissional e técnica por município e ano. |
| `srv_escola_ano_em` | escola/ano | 1,533,848 | 93 | Estrutura, infraestrutura, oferta e matrículas das escolas com Ensino Médio. |
| `srv_escola_ano_tecnico` | escola/ano | 17,438 | 44 | Oferta de cursos técnicos e matrículas profissionais por escola e ano. |
| `srv_escola_ano_em_tecnico` | escola/ano | 1,533,848 | 79 | Coexistência de Ensino Médio e educação técnica na mesma escola e ano. |

## Como relacionar as tabelas

- Entre tabelas municipais: `ano + id_municipio`.
- Entre tabelas escolares: `ano + id_municipio + id_escola`.
- De escola para município: `ano + id_municipio`.
- Use `LEFT JOIN` a partir da população da análise, porque as tabelas técnicas
  têm cobertura mais restrita.

O arquivo `metadata/relacionamentos_tabelas.csv` e a aba `relacionamentos` do
dicionário detalham todas as combinações recomendadas.

## Metadados e qualidade

- `metadata/inventario_tabelas.csv`: volume, grão, chave e foco.
- `metadata/dicionario_colunas.csv`: dicionário consolidado das 521 colunas.
- `metadata/Dicionario_Serving_Zenodo.xlsx`: versão navegável do dicionário.
- `metadata/relacionamentos_tabelas.csv`: chaves e cardinalidades esperadas.
- `metadata/relatorio_qualidade.csv`: completude e unicidade das chaves,
  cobertura temporal e conferência entre DuckDB e Parquet.
- `SHA256SUMS`: integridade dos arquivos do pacote.

## Leitura rápida

Python:

```python
import pandas as pd
df = pd.read_parquet("data/srv_municipio_ano_painel_educacional.parquet")
```

DuckDB:

```sql
select *
from read_parquet('data/srv_municipio_ano_painel_educacional.parquet');
```

## Fontes

- INEP: Censo Escolar 2019–2025.
- INEP: resultados municipais do SAEB 2019, 2021 e 2023.
- IBGE: PIB municipal 2019–2023 e Censo Demográfico 2022.
- Diretório de municípios usado para harmonização territorial.

## Limitações

- O desenho é observacional; associações não identificam causalidade.
- O SAEB está no grão municipal e foi observado apenas em 2019, 2021 e 2023.
- Valores vigentes por ciclo não representam novas aplicações do SAEB.
- Não há fonte direta de abandono, reprovação ou evasão.
- A cobertura detalhada de cursos técnicos concentra-se em 2023–2025.
- Pandemia e diferenças entre redes coincidem com o período analisado.
- As tabelas representam médias e agregações analíticas; consulte o dicionário
  antes de interpretar qualquer indicador.

## Licença

Licença declarada para este pacote: CC-BY-4.0. A reutilização deve citar
este depósito e também respeitar e atribuir as fontes originais.
