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
resource "aws_vpc" "vpc_g3" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "vpc-g3"
  }
}

# Sub-rede pública
resource "aws_subnet" "subrede_publica" {
  vpc_id     = aws_vpc.vpc_g3.id
  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "subrede-publica"
  }
}

# Sub-rede privada
resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_g3.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.0.128/25"
  tags = {
    Name = "subrede-privada"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw_g3" {
  vpc_id = aws_vpc.vpc_g3.id
  tags = {
    Name = "g3-igw"
  }
}

# Route Table
resource "aws_route_table" "route_table_publica" {
  vpc_id = aws_vpc.vpc_g3.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_g3.id
  }
  tags = {
    Name = "subrede-publica-route-table"
  }
}

resource "aws_route_table_association" "subrede_publica" {
  subnet_id      = aws_subnet.subrede_publica.id
  route_table_id = aws_route_table.route_table_publica.id
}

# Security Group instância pública (Front-End)
resource "aws_security_group" "sg_publica" {
  name        = "sg_publica"
  description = "Acesso SSH"
  vpc_id      = aws_vpc.vpc_g3.id

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

# Security Group instância pública (RabbitMQ)
resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq-sg"
  description = "Trafego para RabbitMQ e SSH"
  vpc_id      = aws_vpc.vpc_g3.id

  ingress {
    description = "Acesso SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "AMQP"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ UI"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG RabbitMQ"
  }
}

# Security Group instância privada (Banco de Dados)
resource "aws_security_group" "sg_privada_bd" {
  name        = "sg_privada_bd"
  description = "Acesso SSH da mesma VPC e entre EC2 privadas"
  vpc_id      = aws_vpc.vpc_g3.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_g3.cidr_block]
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
  vpc_id      = aws_vpc.vpc_g3.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_g3.cidr_block]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_g3.cidr_block]
  }

  ingress {
    from_port   = 0     
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subrede_privada.cidr_block]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis insight"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis insight bind port"
    from_port   = 5540
    to_port     = 5540
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

# Instância EC2 pública (Front-End)
resource "aws_instance" "ec2_publica_nginx" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  private_ip                  = "10.0.0.11"
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

# Instância EC2 pública (RabbitMQ)
resource "aws_instance" "ec2_rabbitmq" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro" 
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.rabbitmq_sg.id]
  private_ip                  = "10.0.0.10"
  associate_public_ip_address = true

  user_data = join("\n\n", [
    "#!/bin/bash",
    file("scripts/setup.sh"),
    templatefile("scripts/run_rabbitmq.sh", {
      arquivo_docker_compose = base64encode(file("../Docker/RabbitMQ/compose.yaml"))
    })
  ])

  tags = {
    Name = "ec2-rabbitmq"
  }
}

output "url_gerenciador_rabbitmq" {
  description = "URL do Management UI do RabbitMQ"
  value       = "http://${aws_instance.ec2_rabbitmq.public_ip}:15672"
}

# Instância EC2 privada (Banco de Dados)
resource "aws_instance" "ec2_privada_bd" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada_bd.id]
  private_ip                  = "10.0.0.200"
  associate_public_ip_address = false

  user_data = join("\n\n", [
    "#!/bin/bash",
    file("scripts/setup.sh"),
    templatefile("scripts/run_bd.sh", {
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
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_iam_instance_profile" "ec2_back_profile" {
  name = "LabRole"
  role = data.aws_iam_role.lab_role.name
}

resource "aws_instance" "ec2_privada_be" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada_back.id]
  private_ip                  = "10.0.0.201"
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_back_profile.name

  user_data = join("\n\n", [
    "#!/bin/bash",
    "sleep 15",
    file("scripts/setup.sh"),
    templatefile("scripts/run_back.sh", {
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
  vpc_id = aws_vpc.vpc_g3.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "subrede-privada-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.subrede_privada.id
  route_table_id = aws_route_table.route_table_privada.id
}

# Bucket
variable "bucket_name" {
  description = "Nome único do bucket S3"
  type        = string
  default     = "bucket-teste-g3" # Mudar para o nome do seu bucket
}

resource "aws_s3_bucket" "bucket_g3" {
  bucket = var.bucket_name 
  force_destroy = true
}

resource "aws_s3_object" "directory_files" {
  for_each = fileset("./Imagens_S3", "**")
  bucket   = aws_s3_bucket.bucket_g3.id
  key      = "${each.value}"
  source   = "./Imagens_S3/${each.value}"
}

resource "aws_s3_bucket_public_access_block" "bloco_acesso_publico_s3" {
  bucket = aws_s3_bucket.bucket_g3.bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "politica_acesso_publico_bucket" {
  bucket = aws_s3_bucket.bucket_g3.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
})

  depends_on = [aws_s3_bucket_public_access_block.bloco_acesso_publico_s3]
}