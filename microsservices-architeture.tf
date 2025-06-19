# EC2 Instance para User Service
resource "aws_instance" "user_service_new" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    
    # Create custom server
    cat > /tmp/server.py << 'EOL'
import http.server
import socketserver
import json
from urllib.parse import urlparse

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"message": "User Service is running!", "service": "users", "status": "active", "path": self.path}
        self.wfile.write(json.dumps(response).encode())

PORT = 80
with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOL
    
    # Start server
    nohup sudo python3 /tmp/server.py > /tmp/server.log 2>&1 &
  EOF
  )

  tags = {
    Name        = "${var.project_name}-user-service-new"
    Environment = var.environment
  }
}

# EC2 Instance para Order Service 
resource "aws_instance" "order_service_new" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    
    # Create custom server
    cat > /tmp/server.py << 'EOL'
import http.server
import socketserver
import json
from urllib.parse import urlparse

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"message": "Order Service is running!", "service": "orders", "status": "active", "path": self.path}
        self.wfile.write(json.dumps(response).encode())

PORT = 80
with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOL
    
    # Start server
    nohup sudo python3 /tmp/server.py > /tmp/server.log 2>&1 &
  EOF
  )

  tags = {
    Name        = "${var.project_name}-order-service-new"
    Environment = var.environment
  }
}

# Attach instances to target groups
resource "aws_lb_target_group_attachment" "user_service_new" {
  target_group_arn = aws_lb_target_group.user_service.arn
  target_id        = aws_instance.user_service_new.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "order_service_new" {
  target_group_arn = aws_lb_target_group.order_service.arn
  target_id        = aws_instance.order_service_new.id
  port             = 80
}
