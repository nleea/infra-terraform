# Outputs del módulo iam-roles

output "execution_role_arn" {
  description = "Rol de ejecución compartido por las tareas ECS."
  value       = aws_iam_role.execution.arn
}

output "task_role_arns" {
  description = "Rol de tarea de cada servicio."
  value       = { for k, r in aws_iam_role.task : k => r.arn }
}
