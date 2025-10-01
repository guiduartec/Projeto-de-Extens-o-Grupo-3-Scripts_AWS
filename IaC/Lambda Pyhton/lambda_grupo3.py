import boto3

# ======== Configuração AWS =======

# Obs>>>>>>>>>> não esquecer de configurar as credenciais AWS no ambiente local

regiao='us-east-1'
nome_bucket_raw='bucket-raw-teste-lambda'
nome_bucket_trusted='bucketz-trusted-teste-lambda'

client = boto3.client('s3', region_name=regiao)
s3 = boto3.resource('s3', region_name=regiao)


def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Lambda grupo 3 funcionando'
    }

def ler_arquivo_s3(fileNameOnBucket):

   try:  
        conteudo_arquivo = client.get_object(Bucket=nome_bucket_raw, Key=fileNameOnBucket)
        dados = conteudo_arquivo['Body'].read().decode('utf-8')
        return dados

        print(dados)

   except Exception as e:
            print("Erro ao ler o arquivo: {e}")    



    