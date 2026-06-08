import pandas as pd

aba_dados = 'Municípios'
# caminho_arquivo = "./data/raw/saeb_2019/Resultados_Saeb_2019_Brasil_Estados_Municipios.xlsx"
# caminho_arquivo = "./data/raw/saeb_2021/saeb_2021_brasil_estados_municipios.xlsx"
caminho_arquivo = "./data/raw/saeb_2023/Resultados_Saeb_2023_Brasil_Estados_Municipios.xlsb"

# caminho_saida_dados = "./data/raw/saeb_2019/saeb_resultados_municipios_2019.csv.gz"
# caminho_saida_dados = "./data/raw/saeb_2021/saeb_resultados_municipios_2021.csv.gz"
caminho_saida_dados = "./data/raw/saeb_2023/saeb_resultados_municipios_2023.csv.gz"

if caminho_arquivo.endswith('.xlsb'):
  df = pd.read_excel(caminho_arquivo, sheet_name=aba_dados, engine='pyxlsb')
else:
  df = pd.read_excel(caminho_arquivo, sheet_name=aba_dados)

print(f"Comprimindo e salvando em {caminho_saida_dados}...")
df.to_csv(caminho_saida_dados, index=False, sep=';', compression='gzip')

aba_dicionario = 'Dicionário'
caminho_saida_dicionario = "./docs/Dicionario_Resultados_Saeb_2023.csv"

# Apenas para o arquivo .xlsb, pois os arquivos .xlsx não possuem a aba de dicionário
if caminho_arquivo.endswith('.xlsb'):
  print(f"\nExtraindo a aba de dicionário '{aba_dicionario}'...")
  df_dicionario = pd.read_excel(df, sheet_name=aba_dicionario)

  print(f"Salvando dicionário em: {caminho_saida_dicionario}")
  df_dicionario.to_csv(caminho_saida_dicionario, index=False, sep=';')
