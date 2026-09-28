# Outputs del módulo ecs-service

output "service_name" {
  description = "Nombre del servicio ECS."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN de la revisión actual de la task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "Log group de los contenedores."
  value       = aws_cloudwatch_log_group.this.name
}
