# Valores derivados comunes del bootstrap dev
locals {
  session_name = "terraform-bootstrap-${var.project}-${var.environment}"

  default_tags = merge(var.additional_tags, {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Repository  = var.repository
    Component   = "terraform-bootstrap"
  })
}
