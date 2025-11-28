import pandas as pd
import numpy as np
import boto3
import io
import json
import csv
from datetime import datetime

# Configurações AWS
regiao = 'us-east-1'
nome_bucket_raw = 'bucket-raw-g3-venuste-v2'
nome_bucket_trusted = 'bucket-trusted-g3-venuste-v2'
arquivo_weather = 'weather_sum_2024.csv'

# Inicialização dos clientes AWS
s3_client = boto3.client('s3', region_name=regiao)
s3_resource = boto3.resource('s3', region_name=regiao)

def ler_arquivo_s3():

    try:
        print(f"Tentando ler arquivo {arquivo_weather} do bucket {nome_bucket_raw}")
        response = s3_client.get_object(Bucket=nome_bucket_raw, Key=arquivo_weather)
        
        df = pd.read_csv(
            io.BytesIO(response['Body'].read()),
            na_values=['', 'NULL', 'null', 'NA', 'na', ' ', '#N/A'],
            keep_default_na=True,
            dtype_backend='numpy_nullable'
        )
        print(f"Arquivo lido com sucesso. Shape: {df.shape}")
        return df
        
    except s3_client.exceptions.NoSuchKey:
        error_msg = f"Arquivo {arquivo_weather} não encontrado no bucket {nome_bucket_raw}"
        print(error_msg)
        raise FileNotFoundError(error_msg)
    except Exception as e:
        error_msg = f"Erro ao ler arquivo do S3: {str(e)}"
        print(error_msg)
        raise Exception(error_msg)

def salvar_arquivo_s3(df):

    try:
        print(f"Preparando para salvar arquivo no bucket {nome_bucket_trusted}")
        
        if df.empty:
            raise ValueError("DataFrame está vazio, nenhum dado para salvar")
            
        # Converter DataFrame para CSV em memória usando ponto-e-vírgula como separador
        csv_buffer = io.StringIO()
        df.to_csv(
            csv_buffer, 
            index=False, 
            sep=';', 
            decimal=',',
            encoding='utf-8',
            quoting=csv.QUOTE_MINIMAL  # Adiciona quotes apenas quando necessário
        )
        
        # Upload para S3 com metadata para melhor identificação
        conteudo = csv_buffer.getvalue().encode('utf-8')
        s3_client.put_object(
            Bucket=nome_bucket_trusted,
            Key=arquivo_weather,
            Body=conteudo,
            ContentType='text/csv',
            Metadata={
                'rows': str(len(df)),
                'columns': str(len(df.columns)),
                'processed-date': datetime.now().isoformat()
            }
        )
        print(f"Arquivo processado salvo com sucesso no bucket {nome_bucket_trusted}")
        print(f"Total de registros salvos: {len(df)}")
        
    except Exception as e:
        error_msg = f"Erro ao salvar arquivo no S3: {str(e)}"
        print(error_msg)
        raise Exception(error_msg)

def process_weather_data_optimized():

    try:
        print("\n=== Iniciando Processamento dos Dados Meteorológicos ===")
        
        # Leitura do CSV do S3
        print("\n1. Leitura do arquivo do S3...")
        df = ler_arquivo_s3()
        
        print("\n2. Iniciando limpeza e transformação dos dados...")
        # Limpar dados nulos
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
        
        final_df = df[columns_to_keep].copy()
        
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
        
        # Salvar no S3
        print("Salvando arquivo processado no S3...")
        salvar_arquivo_s3(final_df)
        
        # Imprimir estatísticas
        print(f"\nEstatísticas do processamento:")
        print(f"Total de dias processados: {len(final_df)}")
        print(f"Registros por estação:")
        print(final_df['estacao'].value_counts())
        print("\nEstatísticas das medições:")
        print(temp_df[numeric_columns].describe().round(2))
        
        return True
    
    except Exception as e:
        print(f"Erro durante o processamento: {e}")
        return False

def lambda_handler(event, context):

    print("\n=== Iniciando Execução Lambda de Processamento Meteorológico ===")
    start_time = datetime.now()
    
    try:
        print(f"Timestamp início: {start_time.isoformat()}")
        print(f"Função Lambda: {context.function_name if context else 'Local'}")
        print(f"Request ID: {context.aws_request_id if context else 'Local'}")
        
        success = process_weather_data_optimized()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        if success:
            message = {
                'status': 'success',
                'message': 'Processamento meteorológico concluído com sucesso!',
                'duration_seconds': duration,
                'timestamp': end_time.isoformat()
            }
            print(f"\nProcessamento concluído com sucesso em {duration:.2f} segundos")
            return {
                'statusCode': 200,
                'body': json.dumps(message)
            }
        else:
            message = {
                'status': 'error',
                'message': 'Falha no processamento dos dados meteorológicos',
                'duration_seconds': duration,
                'timestamp': end_time.isoformat()
            }
            print(f"\nProcessamento falhou após {duration:.2f} segundos")
            return {
                'statusCode': 500,
                'body': json.dumps(message)
            }
            
    except Exception as e:
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        error_message = {
            'status': 'error',
            'message': f'Erro: {str(e)}',
            'duration_seconds': duration,
            'timestamp': end_time.isoformat()
        }
        print(f"\nErro na execução da Lambda após {duration:.2f} segundos: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(error_message)
        }

# Permite testar o código localmente
if __name__ == "__main__":
    print("Iniciando processamento dos dados meteorológicos localmente...")
    # Simula uma chamada Lambda local
    response = lambda_handler({}, None)
    print(f"\nResultado da execução:")
    print(f"Status: {response['statusCode']}")
    print(f"Mensagem: {json.loads(response['body'])}")