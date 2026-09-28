# Configuración del provider AWS del entorno dev
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Evita aplicar por error sobre una cuenta distinta a la del entorno
  allowed_account_ids = [var.aws_account_id]

  # En CI las credenciales llegan por OIDC; en local se asume el rol si se define
  dynamic "assume_role" {
    for_each = var.assume_role_arn == null ? [] : [var.assume_role_arn]

    content {
      role_arn     = assume_role.value
      session_name = local.session_name
    }
  }

  default_tags {
    tags = local.default_tags
  }
}
