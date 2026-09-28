# Valores derivados comunes del entorno prod
locals {
  name_prefix  = "${var.project}-${var.environment}"
  session_name = "terraform-${local.name_prefix}"

  default_tags = merge(var.additional_tags, {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Repository  = var.repository
  })
}
