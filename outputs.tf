output "database_endpoint" {
  description = "Endpoint do banco de dados RDS"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_port" {
  description = "Porta do banco de dados"
  value       = aws_db_instance.main.port
}

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "microservices_url" {
  description = "URL dos microservices"
  value       = "http://${aws_lb.microservices.dns_name}"
}

output "user_service_ip" {
  description = "IP público do User Service"
  value       = aws_instance.user_service_new.public_ip
}

output "order_service_ip" {
  description = "IP público do Order Service"
  value       = aws_instance.order_service_new.public_ip
}
