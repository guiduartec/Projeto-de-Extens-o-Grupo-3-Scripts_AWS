import pandas as pd
import numpy as np
import os
from datetime import datetime

def process_weather_data_optimized():
    # Configuração de caminhos
    base_path = os.path.dirname(os.path.dirname(__file__))
    weather_path = os.path.join(base_path, 'main_terraform', 'weather_sum_2024', 'weather_sum_2024.csv')
    output_path = os.path.join(base_path, 'main_terraform', 'weather_processed.csv')
    
    try:
        # Leitura otimizada do CSV
        df = pd.read_csv(
            weather_path,
            na_values=['', 'NULL', 'null', 'NA', 'na', ' ', '#N/A'],  # Valores a serem tratados como NA
            keep_default_na=True,
            dtype_backend='numpy_nullable'  # Melhor suporte para valores nulos
        )
        
        # Primeiro, vamos limpar os dados nulos
        df = df.fillna({
            'ESTACAO': '',
            'DATA (YYYY-MM-DD)': ''
        })
        
        # Limpar espaços em branco e padronizar strings
        df['ESTACAO'] = df['ESTACAO'].astype(str).str.strip().str.upper()
        df['DATA (YYYY-MM-DD)'] = df['DATA (YYYY-MM-DD)'].astype(str).str.strip()
        
        # Filtrar apenas as estações desejadas e remover linhas totalmente vazias
        df = df[
            (df['ESTACAO'].isin(['A771', 'A701'])) & 
            (~df.isna().all(axis=1))
        ]
        
        # Criar timestamp de forma otimizada
        df['timestamp'] = pd.to_datetime(df['DATA (YYYY-MM-DD)'])
        
        # Extrair apenas a data para agrupamento
        df['date'] = df['timestamp'].dt.date
        
        # Renomear colunas para nomes mais simples
        column_mapping = {
            'temp_avg': 'temperatura',
            'rain_max': 'precipitacao',
            'rad_max': 'radiacao',
            'hum_max': 'umidade',
            'wind_max': 'velocidade_vento',
            'ESTACAO': 'estacao'
        }
        df = df.rename(columns=column_mapping)
        
        # Como já temos dados diários, não precisamos agrupar
        daily_records = df.copy()
        
        # Selecionar colunas relevantes
        columns_to_keep = [
            'timestamp',
            'temperatura',
            'precipitacao',
            'radiacao',
            'umidade',
            'velocidade_vento',
            'estacao'
        ]
        
        final_df = daily_records[columns_to_keep].copy()
        
        # Tratar valores numéricos
        numeric_columns = ['temperatura', 'precipitacao', 'radiacao', 'umidade', 'velocidade_vento']
        
        # Criar uma cópia para manipulação
        temp_df = final_df.copy()
        
        # Converter colunas numéricas para float, permitindo NaN
        for col in numeric_columns:
            temp_df[col] = pd.to_numeric(temp_df[col], errors='coerce')
        
        # Remover registros onde todos os valores numéricos são NaN
        valid_rows = ~temp_df[numeric_columns].isna().all(axis=1)
        final_df = final_df[valid_rows]
        temp_df = temp_df[valid_rows]
        
        # Arredondar e formatar valores numéricos
        for col in numeric_columns:
            # Arredondar valores não-nulos
            temp_df[col] = temp_df[col].round(2)
            # Converter para string formatada, usando 'N/A' para NaN
            final_df[col] = temp_df[col].apply(lambda x: f"{x:.2f}" if pd.notnull(x) else 'N/A')
        
        # Converter timestamp para ISO
        final_df['timestamp'] = final_df['timestamp'].dt.strftime('%Y-%m-%dT%H:%M:%S')
        
        # Salvar resultado em CSV
        final_df.to_csv(output_path, index=False)
        
        # Imprimir estatísticas
        print(f"\nEstatísticas do processamento:")
        print(f"Total de dias processados: {len(final_df)}")
        print(f"Registros por estação:")
        print(final_df['estacao'].value_counts())
        print("\nEstatísticas das medições:")
        print(temp_df[numeric_columns].describe().round(2))
        
        return output_path

    except Exception as e:
        raise Exception(f"Erro ao processar dados: {str(e)}")

if __name__ == "__main__":
    try:
        output_file = process_weather_data_optimized()
        print("\nDados processados com sucesso!")
        print(f"Arquivo de saída gerado em: {output_file}")
        
        # Mostrar preview dos dados
        df = pd.read_csv(output_file)
        print("\nPreview dos dados processados (primeiros registros):")
        print(df.head(10).to_string())
        
    except Exception as e:
        print(f"Erro ao processar dados: {str(e)}")