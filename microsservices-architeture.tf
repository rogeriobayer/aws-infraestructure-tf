# ECS Cluster para microserviços
resource "aws_ecs_cluster" "microservices" {
  name = "${var.project_name}-microservices-cluster"

  tags = {
    Name        = "${var.project_name}-ecs-cluster"
    Environment = var.environment
  }
}

# Service Discovery namespace
resource "aws_service_discovery_private_dns_namespace" "microservices" {
  name        = "${var.project_name}.local"
  description = "Service discovery for microservices"
  vpc         = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-service-discovery"
    Environment = var.environment
  }
}

# User Service
resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.microservices.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.microservices.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.user_service.arn
  }

  depends_on = [aws_lb_listener.microservices]
}

# Order Service
resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.microservices.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.microservices.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order_service.arn
  }

  depends_on = [aws_lb_listener.microservices]
}

# Task Definitions
resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "user-service"
      image = "kennethreitz/httpbin"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "order-service"
      image = "nginx:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Service Discovery Services
resource "aws_service_discovery_service" "user_service" {
  name = "user-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.microservices.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "order_service" {
  name = "order-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.microservices.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
