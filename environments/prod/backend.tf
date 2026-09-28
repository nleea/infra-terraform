# Configuración del backend remoto de estado del entorno prod
# Configuración parcial: bucket, región, tabla de lock y rol se pasan con
#   terraform init -backend-config=backend.hcl
# backend.hcl lo genera el output "backend_config" de bootstrap/prod.
terraform {
  backend "s3" {
    key     = "prod/terraform.tfstate"
    encrypt = true
  }
}
