#!/bin/bash

# Iniciando container da aplicação (BD)
echo "${arquivo_docker_compose}" | base64 -d > /home/ec2-user/compose.yaml
sudo nohup docker compose -f /home/ec2-user/compose.yaml up -d &
echo "Aplicação iniciada com sucesso"