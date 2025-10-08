import boto3
import json

# ======== Configuração AWS =======

# Obs>>>>>>>>>> não esquecer de configurar as credenciais AWS no ambiente local

regiao='us-east-1'
nome_bucket_raw='bucket-raw-teste-lambda'
nome_bucket_trusted='bucketz-trusted-teste-lambda'

client = boto3.client('s3', region_name=regiao)
s3 = boto3.resource('s3', region_name=regiao)


def lambda_handler(event, context):

    try:
        objetos = client.list_objects_v2(Bucket=nome_bucket_raw)

        if 'Contents' not in objetos:
            return {
                'statusCode': 200,
                'body': json.dumps('Nenhum arquivo encontrado no bucket RAW.')
            }
    
        for obj in objetos['Contents']:
            nome_arquivo = obj['Key']
            print(f"Lendo arquivo: {nome_arquivo}")

            dados = ler_arquivo_s3(nome_arquivo)

            enviar_para_trusted(nome_arquivo, dados)

        return {
            'statusCode': 200,
            'body': json.dumps('Arquivos transferidos com sucesso para o bucket TRUSTED!')
        }

    except Exception as e:
        print(f"Erro na execução da Lambda: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erro: {str(e)}")
        }


def ler_arquivo_s3(fileNameOnBucket):

   try:  
        conteudo_arquivo = client.get_object(Bucket=nome_bucket_raw, Key=fileNameOnBucket)
        dados = conteudo_arquivo['Body'].read().decode('utf-8')
        return dados

   except Exception as e:
            print("Erro ao ler o arquivo: {e}")    


def enviar_para_trusted(nome_arquivo, dados):
    try:
        if dados is not None:
            # Grava o arquivo no bucket trusted
            client.put_object(
                Bucket=nome_bucket_trusted,
                Key=nome_arquivo,
                Body=dados.encode('utf-8')
            )
            print(f"Arquivo {nome_arquivo} enviado para o bucket TRUSTED.")
        else:
            print(f"Arquivo {nome_arquivo} não possui dados válidos.")
    except Exception as e:
        print(f"Erro ao enviar o arquivo {nome_arquivo} para o bucket TRUSTED: {e}")
    