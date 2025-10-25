#!/bin/bash

# Iniciando container da aplicação (Back)
echo "${arquivo_env}" | base64 -d > /home/ec2-user/.env
echo -e "\nDB_HOST=${ip_ec2_bd}" >> /home/ec2-user/.env
echo "${arquivo_docker_compose}" | base64 -d > /home/ec2-user/compose.yaml
sudo nohup docker compose -f /home/ec2-user/compose.yaml up -d &
echo "Aplicação iniciada com sucesso"