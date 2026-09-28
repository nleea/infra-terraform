# Recursos y llamadas a módulos del entorno dev
# Toda la lógica vive en modules/platform; el entorno solo aporta sus valores (terraform.tfvars).

module "platform" {
  source = "../../modules/platform"

  name = local.name_prefix

  vpc_cidr                       = var.vpc_cidr
  az_count                       = var.az_count
  nat_gateway_mode               = var.nat_gateway_mode
  vpc_interface_endpoints        = var.vpc_interface_endpoints
  log_retention_days             = var.log_retention_days
  ecs_container_insights         = var.ecs_container_insights
  ecs_capacity_provider_strategy = var.ecs_capacity_provider_strategy
  alb_certificate_arn            = var.alb_certificate_arn
  alb_ingress_cidrs              = var.alb_ingress_cidrs
  alb_deletion_protection        = var.alb_deletion_protection
  alb_access_logs_enabled        = var.alb_access_logs_enabled
  waf_enabled                    = var.waf_enabled
  waf_rate_limit                 = var.waf_rate_limit
  db_engine_version              = var.db_engine_version
  db_instance_class              = var.db_instance_class
  db_allocated_storage           = var.db_allocated_storage
  db_max_allocated_storage       = var.db_max_allocated_storage
  db_name                        = var.db_name
  db_master_username             = var.db_master_username
  db_port                        = var.db_port
  db_multi_az                    = var.db_multi_az
  db_backup_retention_days       = var.db_backup_retention_days
  db_deletion_protection         = var.db_deletion_protection
  services                       = var.services
}
