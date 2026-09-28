# Outputs del módulo security

output "alb_security_group_id" {
  description = "Security group del ALB."
  value       = aws_security_group.alb.id
}

output "services_security_group_id" {
  description = "Security group de los servicios ECS."
  value       = aws_security_group.services.id
}

output "database_security_group_id" {
  description = "Security group de la base de datos."
  value       = aws_security_group.database.id
}
