# Load Balancer para Microservices 
resource "aws_lb" "microservices" {
  name               = "rogerio-micro-alb"  
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-microservices-alb"
    Environment = var.environment
  }
}

# Target Groups para Microservices
resource "aws_lb_target_group" "user_service" {
  name        = "rogerio-user-tg"  
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-user-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "order_service" {
  name        = "rogerio-order-tg"  
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-order-tg"
    Environment = var.environment
  }
}

# Listener para Microservices
resource "aws_lb_listener" "microservices" {
  load_balancer_arn = aws_lb.microservices.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Microservices Gateway - Choose /users or /orders"
      status_code  = "200"
    }
  }
}

# Rules para rotear por path
resource "aws_lb_listener_rule" "user_service" {
  listener_arn = aws_lb_listener.microservices.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/users/*", "/users"]
    }
  }
}

resource "aws_lb_listener_rule" "order_service" {
  listener_arn = aws_lb_listener.microservices.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_service.arn
  }

  condition {
    path_pattern {
      values = ["/orders/*", "/orders"]
    }
  }
}
