# Configuración del backend remoto de estado del entorno dev
# Configuración parcial: bucket, región, tabla de lock y rol se pasan con
#   terraform init -backend-config=backend.hcl
# backend.hcl lo genera el output "backend_config" de bootstrap/dev.
terraform {
  backend "s3" {
    key     = "dev/terraform.tfstate"
    encrypt = true
  }
}
