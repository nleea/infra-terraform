# Bootstrap del entorno dev: backend de estado y roles IAM de Terraform.
# Se aplica una vez por cuenta con credenciales de administrador.
module "terraform_bootstrap" {
  source = "../../modules/terraform-bootstrap"

  project                      = var.project
  environment                  = var.environment
  github_repository            = var.repository
  github_oidc_subject_prefix   = var.github_oidc_subject_prefix
  create_github_oidc_provider  = var.create_github_oidc_provider
  plan_trusted_principal_arns  = var.plan_trusted_principal_arns
  apply_trusted_principal_arns = var.apply_trusted_principal_arns
}
