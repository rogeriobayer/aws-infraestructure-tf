# Launch Template para EC2
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    cat > /var/www/html/index.html << HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Infraestrutura AWS - Rogério</title>
        <!-- ... -->
    </head>
    <body>
        <div class="container">
            <h1>🚀 Infraestrutura AWS com Terraform</h1>
            <div class="info">
                <h3>Recursos Provisionados:</h3>
                <ul>
                    <li>✅ Instância EC2 (Amazon Linux 2)</li>
                    <li>✅ Application Load Balancer</li>
                    <li>✅ Banco de dados RDS MySQL</li>
                    <li>✅ VPC com subnets públicas e privadas</li>
                    <li>✅ Security Groups configurados</li>
                </ul>
            </div>
            <p><strong>Servidor:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Região:</strong> $(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print \$4}')</p>
            <p><strong>Projeto:</strong> ${var.project_name}</p>
            <p><strong>Ambiente:</strong> ${var.environment}</p>
        </div>
    </body>
    </html>
    HTML
    
    # Configurar logs do Apache
    echo "LogFormat \"%h %l %u %t \\\"%r\\\" %>s %b  combined" >> /etc/httpd/conf/httpd.conf
    echo "CustomLog /var/log/httpd/access.log combined" >> /etc/httpd/conf/httpd.conf
    
    systemctl restart httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-web-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
