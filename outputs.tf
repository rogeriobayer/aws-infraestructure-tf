output "load_balancer_dns" {
  description = "DNS do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID do Load Balancer"
  value       = aws_lb.main.zone_id
}

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

output "application_url" {
  description = "URL da aplicação"
  value       = "http://${aws_lb.main.dns_name}"
}
