terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

# CIDR 10.0.0.0/24
resource "aws_vpc" "vpc_cco" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "vpc-2cco"
  }
}

# Sub-rede pública
resource "aws_subnet" "subrede_publica" {
  vpc_id     = aws_vpc.vpc_cco.id
  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "subrede-publica"
  }
}

# Ssub-rede privada
resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_cco.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.0.128/25"
  tags = {
    Name = "subrede-privada"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw_cco" {
  vpc_id = aws_vpc.vpc_cco.id
  tags = {
    Name = "cco-igw"
  }
}

# Route Table
resource "aws_route_table" "route_table_publica" {
  vpc_id = aws_vpc.vpc_cco.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_cco.id
  }
  tags = {
    Name = "subrede-publica-route-table"
  }
}

resource "aws_route_table_association" "subrede_publica" {
  subnet_id      = aws_subnet.subrede_publica.id
  route_table_id = aws_route_table.route_table_publica.id
}

# Security Group instância pública
resource "aws_security_group" "sg_publica" {
  name        = "sg_publica"
  description = "Acesso SSH"
  vpc_id      = aws_vpc.vpc_cco.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group instância privada (Banco de Dados)
resource "aws_security_group" "sg_privada_bd" {
  name        = "sg_privada_bd"
  description = "Acesso SSH da mesma VPC e entre EC2 privadas"
  vpc_id      = aws_vpc.vpc_cco.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_cco.cidr_block]
  }

  ingress {
    from_port   = 0     
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subrede_privada.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group instância privada (Back-End)
resource "aws_security_group" "sg_privada_back" {
  name        = "sg_privada_back"
  description = "Acesso SSH da mesma VPC e entre EC2 privadas"
  vpc_id      = aws_vpc.vpc_cco.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_cco.cidr_block]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_cco.cidr_block]
  }

  ingress {
    from_port   = 0     
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subrede_privada.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instância EC2 pública (Front-End)
resource "aws_instance" "ec2_publica_nginx" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true

  user_data = join("\n\n", [
    "#!/bin/bash",
    file("scripts/setup.sh"),
    templatefile("scripts/run_front.sh", {
      arquivo_docker_compose = base64encode(file("../Docker/Front-End/compose.yaml"))
    })
  ])

  user_data_replace_on_change = true

  tags = {
    Name = "ec2-publica-FE"
  }
}


# Instância EC2 privada (Banco de Dados)
resource "aws_instance" "ec2_privada_bd" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada_bd.id]
  private_ip = "10.0.0.200"
  associate_public_ip_address = false

  user_data = join("\n\n", [
    "#!/bin/bash",
    file("scripts/setup.sh"),
    templatefile("scripts/run_bd.sh", {
      arquivo_env            = base64encode(file("../Docker/Database/.env")),
      arquivo_docker_compose = base64encode(file("../Docker/Database/compose.yaml"))
    })
  ])

  user_data_replace_on_change = true

  tags = {
    Name = "ec2-privada-BD"
  }

  depends_on = [aws_route_table_association.private]
}

# Instância EC2 privada (Back-End)
resource "aws_instance" "ec2_privada_be" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada_back.id]
  private_ip = "10.0.0.201"
  associate_public_ip_address = false

  user_data = join("\n\n", [
    "#!/bin/bash",
    "sleep 15",
    file("scripts/setup.sh"),
    templatefile("scripts/run_back.sh", {
      ip_ec2_bd              = aws_instance.ec2_privada_bd.private_ip,
      arquivo_env            = base64encode(file("../Docker/Back-End/.env")),
      arquivo_docker_compose = base64encode(file("../Docker/Back-End/compose.yaml"))
    })
  ])

  user_data_replace_on_change = true

  tags = {
    Name = "ec2-privada-BE"
  }

  depends_on = [aws_instance.ec2_privada_bd]
}

# NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.subrede_publica.id
}

resource "aws_route_table" "route_table_privada" {
  vpc_id = aws_vpc.vpc_cco.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.subrede_privada.id
  route_table_id = aws_route_table.route_table_privada.id
}
