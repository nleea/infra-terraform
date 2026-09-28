# Outputs del módulo platform

output "vpc_id" {
  description = "ID de la VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets públicas (ALB)."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Subnets privadas (servicios ECS)."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Subnets aisladas (RDS)."
  value       = module.vpc.database_subnet_ids
}

output "nat_public_ips" {
  description = "IPs de salida a internet del entorno."
  value       = module.vpc.nat_public_ips
}

output "alb_dns_name" {
  description = "DNS público del ALB."
  value       = module.alb.dns_name
}

output "waf_web_acl_arn" {
  description = "Web ACL que protege el ALB (null si WAF está desactivado)."
  value       = one(module.waf[*].web_acl_arn)
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_names" {
  description = "Servicios ECS desplegados."
  value       = { for k, s in module.ecs_service : k => s.service_name }
}

output "db_address" {
  description = "Hostname de la base de datos."
  value       = module.rds.address
}

output "db_master_user_secret_arn" {
  description = "Secret con las credenciales del administrador de la base de datos."
  value       = module.rds.master_user_secret_arn
}

output "logs_kms_key_arn" {
  description = "Clave KMS de los log groups."
  value       = module.logs_kms_key.arn
}
