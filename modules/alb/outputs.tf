# Outputs del módulo alb

output "arn" {
  description = "ARN del ALB."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "DNS público del ALB."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Hosted zone del ALB (para registros ALIAS en Route 53)."
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "ARN de cada target group, por servicio."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "listener_rule_arns" {
  description = "ARN de la regla de cada servicio en el listener."
  value       = { for k, r in aws_lb_listener_rule.this : k => r.arn }
}
