
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



output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.microservices.name
}
