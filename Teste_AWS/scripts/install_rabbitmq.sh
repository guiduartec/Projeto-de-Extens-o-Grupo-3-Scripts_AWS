#!/bin/bash
set -e

echo "Iniciando a instalação do RabitMQ"

sudo dnf install -y docker
echo "Docker instalado com sucesso."

sudo systemctl enable docker
echo "Docker habilitado para iniciar na inicialização."

sudo systemctl start docker
echo "Docker iniciado com sucesso."

sudo usermod -aG docker ec2-user
echo "Usuário ec2-user adicionado ao grupo docker."

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins

sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/libexec/docker/cli-plugins/docker-compose
echo "Docker Compose baixado com sucesso..."

sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
echo "Permissões do Docker Compose ajustadas com sucesso..."

sudo docker compose -f /home/ec2-user/compose.yaml up -d
echo "RabbitMQ iniciado com sucesso."
