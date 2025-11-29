import pymysql
import pandas as pd
import boto3
import os

# ----------------------------
# CONFIGURAÇÕES DO USUÁRIO
# ----------------------------
HOST = "localhost"
USER = "root"
PASSWORD = "#Gf49053476881"
DATABASE = "projeto_extensao"

BUCKET = "bucket-client-g3-venuste-v2"
PASTA = "weather/"

conn = pymysql.connect(
    host=HOST,
    user=USER,
    password=PASSWORD,
    db=DATABASE
)

cursor = conn.cursor()

# Pegando todas as tabelas do banco
cursor.execute("SHOW TABLES;")
tabelas = [t[0] for t in cursor.fetchall()]

print("Tabelas encontradas:", tabelas)

s3 = boto3.client("s3")

# ----------------------------
# EXPORTAR E ENVIAR PARA S3
# ----------------------------
for tabela in tabelas:
    print(f"Exportando {tabela}...")
    prefix = f"{tabela}/"  # exemplo: alerta/, parceiro/, saida_estoque/
    
    s3.put_object(
        Bucket=BUCKET,
        Key=prefix  # cria o prefixo
    )
    
    print(f"Pasta criada (prefixo): {prefix}")

    # Exporta SELECT *
    df = pd.read_sql(f"SELECT * FROM {tabela}", conn)

    # Gera arquivo CSV local
    nome_csv = f"{tabela}.csv"
    df.to_csv(nome_csv, index=False, sep=";")

    print(f"Enviando {nome_csv} para S3...")

    # Envia para o bucket/pasta no S3
    s3.upload_file(nome_csv, BUCKET, f"{tabela}/{nome_csv}")

    # Remover CSV local (opcional)
    os.remove(nome_csv)

cursor.close()
conn.close()

print("Finalizado! CSVs exportados e enviados para o S3.")