
import pandas as pd
import boto3
import io
import json
import csv
from datetime import datetime

# Configurações AWS
regiao = 'us-east-1'
nome_bucket_trusted = 'bucket-trusted-g3-venuste-v2'
nome_bucket_client = 'bucket-client-g3-venuste-v2'
arquivo_entrada = 'weather_sum_2025.csv'
arquivo_saida = 'csv_client.csv'

# Inicialização dos clientes AWS
s3_client = boto3.client('s3', region_name=regiao)
s3_resource = boto3.resource('s3', region_name=regiao)

def ler_arquivo_s3():
    """
    Lê o arquivo CSV do bucket trusted
    """
    try:
        print(f"Tentando ler arquivo {arquivo_entrada} do bucket {nome_bucket_trusted}")
        response = s3_client.get_object(Bucket=nome_bucket_trusted, Key=arquivo_entrada)
       
        df = pd.read_csv(
            io.BytesIO(response['Body'].read()),
            sep=';'  # Usando ponto-e-vírgula como separador pois o arquivo vem do trusted
        )
        print(f"Arquivo lido com sucesso. Shape: {df.shape}")
        return df
       
    except s3_client.exceptions.NoSuchKey:
        error_msg = f"Arquivo {arquivo_entrada} não encontrado no bucket {nome_bucket_trusted}"
        print(error_msg)
        raise FileNotFoundError(error_msg)
    except Exception as e:
        error_msg = f"Erro ao ler arquivo do S3: {str(e)}"
        print(error_msg)
        raise Exception(error_msg)

def salvar_arquivo_s3(df):
    """
    Salva o DataFrame processado no bucket client
    """
    try:
        print(f"Preparando para salvar arquivo no bucket {nome_bucket_client}")
       
        if df.empty:
            raise ValueError("DataFrame está vazio, nenhum dado para salvar")
           
        # Converter DataFrame para CSV em memória usando ponto-e-vírgula como separador
        csv_buffer = io.StringIO()
        df.to_csv(
            csv_buffer,
            index=False,
            sep=';',
            decimal='.',
            encoding='utf-8',
            quoting=csv.QUOTE_MINIMAL
        )
       
        # Upload para S3 com metadata para melhor identificação
        conteudo = csv_buffer.getvalue().encode('utf-8')
        s3_client.put_object(
            Bucket=nome_bucket_client,
            Key=arquivo_saida,
            Body=conteudo,
            ContentType='text/csv',
            Metadata={
                'rows': str(len(df)),
                'columns': str(len(df.columns)),
                'processed-date': datetime.now().isoformat()
            }
        )
        print(f"Arquivo processado salvo com sucesso no bucket {nome_bucket_client}")
        print(f"Total de registros salvos: {len(df)}")
       
    except Exception as e:
        error_msg = f"Erro ao salvar arquivo no S3: {str(e)}"
        print(error_msg)
        raise Exception(error_msg)
   
def calculate_monthly_averages():
    """
    Calcula as médias mensais de temperatura por estação
    """
    try:
        print("\n=== Iniciando Cálculo de Médias Mensais ===")
       
        # Leitura do CSV do S3
        print("\n1. Leitura do arquivo do bucket trusted...")
        df = ler_arquivo_s3()
       
        print("\n2. Processando dados...")
        # Converter timestamp para datetime para extrair mês
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df['mes'] = df['timestamp'].dt.month
       
        # Converter temperatura para numérico, ignorando 'N/A'
        df['temperatura'] = pd.to_numeric(df['temperatura'], errors='coerce')
       
        # Calcular médias mensais por estação
        monthly_avg = df.groupby(['estacao', 'mes'])['temperatura'].agg([
            ('temperatura_media', 'mean')
        ]).round(2).reset_index()
       
        # Ordenar por estação e mês
        monthly_avg = monthly_avg.sort_values(['estacao', 'mes'])
       
        # Adicionar nome do mês
        meses = {
            1: 'Janeiro', 2: 'Fevereiro', 3: 'Março',
            4: 'Abril', 5: 'Maio', 6: 'Junho',
            7: 'Julho', 8: 'Agosto', 9: 'Setembro',
            10: 'Outubro', 11: 'Novembro', 12: 'Dezembro'
        }
        monthly_avg['nome_mes'] = monthly_avg['mes'].map(meses)

        monthly_avg['data'] = pd.to_datetime(
        monthly_avg['mes'].astype(str) + '-2025', format='%m-%Y'
        )
       
        # Reordenar colunas
        monthly_avg = monthly_avg[['estacao', 'data', 'mes', 'nome_mes', 'temperatura_media']]
       
        # Salvar no S3
        print("\n3. Salvando resultados no bucket client...")
        salvar_arquivo_s3(monthly_avg)
       
        # Imprimir resultados
        print("\nMédias mensais de temperatura por estação:")
        print("\nEstação A701:")
        print(monthly_avg[monthly_avg['estacao'] == 'A701'].to_string(index=False))
       
        # Calcular e mostrar médias anuais
        print("\nMédias anuais por estação:")
        annual_avg = df.groupby('estacao')['temperatura'].mean().round(2)
        for estacao, media in annual_avg.items():
            print(f"Estação {estacao}: {media}°C")
       
        return True
       
    except Exception as e:
        print(f"Erro durante o processamento: {e}")
        return False

def lambda_handler(event, context):
    """
    Handler da função Lambda AWS
    """
    print("\n=== Iniciando Execução Lambda de Cálculo de Médias Mensais ===")
    start_time = datetime.now()
   
    try:
        print(f"Timestamp início: {start_time.isoformat()}")
        print(f"Função Lambda: {context.function_name if context else 'Local'}")
        print(f"Request ID: {context.aws_request_id if context else 'Local'}")
       
        success = calculate_monthly_averages()
       
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
       
        if success:
            message = {
                'status': 'success',
                'message': 'Processamento das médias mensais concluído com sucesso!',
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
                'message': 'Falha no processamento das médias mensais',
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
    print("Iniciando processamento das médias mensais localmente...")
    # Simula uma chamada Lambda local
    response = lambda_handler({}, None)
    print(f"\nResultado da execução:")
    print(f"Status: {response['statusCode']}")
    print(f"Mensagem: {json.loads(response['body'])}")

