# Data Sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Configurações do Grafana

# IAM Roles (usando roles existentes do laboratório AWS Academy)
data "aws_iam_role" "lab_role" {
  name = "LabRole"  # Esta é a role padrão do AWS Academy
}

# Network e Security
resource "aws_security_group" "grafana_sg" {
  name_prefix = "grafana-sg"
  vpc_id      = data.aws_vpc.default.id

  # HTTP access
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Grafana Security Group"
  }
}

# Cluster e Load Balancer
resource "aws_ecs_cluster" "grafana_cluster" {
  name = "grafana-venuste-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "Grafana Cluster"
  }
}

# resource "aws_lb" "grafana_alb" {
#   name               = "grafana-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.grafana_sg.id]
#   subnets           = data.aws_subnets.default.ids

#   tags = {
#     Name = "Grafana ALB"
#   }
# }

# resource "aws_lb_target_group" "grafana_tg" {
#   name        = "grafana-tg"
#   port        = 3000
#   protocol    = "HTTP"
#   vpc_id      = data.aws_vpc.default.id
#   target_type = "ip"

#   health_check {
#     path                = "/api/health"
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#     timeout             = 60
#     interval            = 300
#     matcher            = "200"
#   }
# }

# resource "aws_lb_listener" "grafana_listener" {
#   load_balancer_arn = aws_lb.grafana_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.grafana_tg.arn
#   }
# }

# ECS Task e Service
resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana-venuste"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 512
  memory                  = 1024
  execution_role_arn      = data.aws_iam_role.lab_role.arn
  task_role_arn           = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "grafana/grafana:latest"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://localhost:3000"
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "admin123" # Lembre-se de mudar esta senha em produção
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-venuste-service"
  cluster         = aws_ecs_cluster.grafana_cluster.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.grafana_sg.id]
    assign_public_ip = true
  }

# Removed load balancer configuration as it's optional

  # depends_on = [aws_lb_listener.grafana_listener]
}