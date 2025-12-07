#!/bin/bash

########################################################################
# Configuração inicial
########################################################################
CONTAINER_NAME="db"
DB_USER="root"
DB_PASSWORD="venuste"
DATABASE_NAME="projeto_extensao"
BKP_DIR="/home/ec2-user/backups"
S3_BUCKET="bucket-bkp-g3"
EMAIL_ADMIN="bruno.ytakahashi@sptech.school"

mkdir -p "$BKP_DIR"
docker pull brunoyujitaka/proj_ext_sendemail:latest

TIMESTAMP=$(date +%Y-%m-%d)
BKP_FILE="$BKP_DIR/${DATABASE_NAME}_${TIMESTAMP}.sql"

########################################################################
# Funções
########################################################################
function_iniciar_bkp() {
    echo "Iniciando backup da base '$DATABASE_NAME' no container '$CONTAINER_NAME'..."
    docker exec "$CONTAINER_NAME" /usr/bin/mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DATABASE_NAME" > "$BKP_FILE"

    if [ $? -eq 0 ]; then
        echo "Backup concluído! Salvo em: ${BKP_FILE}"
        return 0
    else
        echo "Ocorreu um erro ao criar o backup!"
        return 1
    fi
}

function_enviar_para_s3() {
    echo "Enviando backup ${BACKUP_FILE} para bucket S3 em s3://${S3_BUCKET}"
    aws s3 cp "${BKP_FILE}" "s3://${S3_BUCKET}/${BACKUP_FILE}"

    if [ $? -eq 0 ]; then
        echo "O arquivo de backup foi enviado com sucesso para o S3!"
        return 0
    else
        echo "Ocorreu um erro ao enviar o backup!"
        return 1
    fi
}

function_enviar_email() {
    if [ $1 -eq 0 ]; then
        ASSUNTO="Backup da base ${DATABASE_NAME} criado com sucesso"
        MENSAGEM="O backup da base de dados ${DATABASE_NAME} foi concluído com sucesso e enviado para o bucket S3: s3://${S3_BUCKET}/${BKP_FILE}"
        docker run brunoyujitaka/proj_ext_sendemail "$ASSUNTO" "$MENSAGEM" "$EMAIL_ADMIN"
        return 0
    elif [ $1 -eq 1 ]; then
        ASSUNTO="Falha ao criar backup da base ${DATABASE_NAME}"
        MENSAGEM="Ocorreu uma falha na criação do backup da base de dados ${DATABASE_NAME}"
        docker run brunoyujitaka/proj_ext_sendemail "$ASSUNTO" "$MENSAGEM" "$EMAIL_ADMIN"
        return 1
    else
        ASSUNTO="Falha ao enviar backup da base ${DATABASE_NAME} para S3"
        MENSAGEM="Ocorreu uma falha no envio do backup da base de dados ${DATABASE_NAME} para o Bucket S3: ${S3_BUCKET}"
        docker run brunoyujitaka/proj_ext_sendemail "$ASSUNTO" "$MENSAGEM" "$EMAIL_ADMIN"
        return 1
    fi
}

########################################################################
# MAIN
########################################################################
function_iniciar_bkp
if [ $? -ne 0 ]; then
    echo "Backup falhou. Abortando o envio para o S3."
    function_enviar_email 1
    exit 1
fi

function_enviar_para_s3
if [ $? -ne 0 ]; then
    echo "Envio para o S3 falhou."
    function_enviar_email 2
    exit 1
fi

function_enviar_email 0
if [ $? -ne 0 ]; then
    echo "Envio do email falhou."
    exit 1
fi

rm -f "$BKP_FILE"
echo "Processo de backup concluído com sucesso."
exit 0