# Outputs del módulo ecs-cluster

output "cluster_id" {
  description = "ID del cluster ECS."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN del cluster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.this.name
}

output "exec_log_group_name" {
  description = "Log group donde se auditan las sesiones de ECS Exec."
  value       = aws_cloudwatch_log_group.exec.name
}

output "exec_log_group_arn" {
  description = "ARN del log group de ECS Exec."
  value       = aws_cloudwatch_log_group.exec.arn
}
