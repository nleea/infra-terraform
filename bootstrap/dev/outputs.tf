# Outputs del bootstrap dev
output "plan_role_arn" {
  description = "Rol para el workflow de plan (secret/variable AWS_PLAN_ROLE_ARN)."
  value       = module.terraform_bootstrap.plan_role_arn
}

output "apply_role_arn" {
  description = "Rol para el workflow de apply (secret/variable AWS_APPLY_ROLE_ARN)."
  value       = module.terraform_bootstrap.apply_role_arn
}

output "backend_config" {
  description = "Contenido de environments/dev/backend.hcl."
  value       = module.terraform_bootstrap.backend_config
}
