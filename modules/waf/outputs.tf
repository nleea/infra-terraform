# Outputs del módulo waf

output "web_acl_arn" {
  description = "ARN del Web ACL."
  value       = aws_wafv2_web_acl.this.arn
}

output "log_group_name" {
  description = "Log group con las peticiones evaluadas por WAF."
  value       = aws_cloudwatch_log_group.this.name
}
