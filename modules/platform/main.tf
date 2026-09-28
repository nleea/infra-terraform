# Plataforma de aplicación completa de un entorno: red, ALB con WAF, ECS, RDS, IAM y cifrado

module "logs_kms_key" {
  source = "../kms-key"

  name                  = "${var.name}-logs"
  description           = "Cifrado de los log groups de ${var.name}"
  allow_cloudwatch_logs = true
}

module "vpc" {
  source = "../vpc"

  name                = var.name
  cidr_block          = var.vpc_cidr
  az_count            = var.az_count
  nat_gateway_mode    = var.nat_gateway_mode
  interface_endpoints = var.vpc_interface_endpoints
  log_retention_days  = var.log_retention_days
  kms_key_arn         = module.logs_kms_key.arn
}

module "ecs_cluster" {
  source = "../ecs-cluster"

  name                               = var.name
  container_insights                 = var.ecs_container_insights
  default_capacity_provider_strategy = var.ecs_capacity_provider_strategy
  log_retention_days                 = var.log_retention_days
  kms_key_arn                        = module.logs_kms_key.arn
}

module "data_kms_key" {
  source = "../kms-key"

  name        = "${var.name}-data"
  description = "Cifrado de datos (RDS y sus secrets) de ${var.name}"
}

module "security" {
  source = "../security"

  name              = var.name
  vpc_id            = module.vpc.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  service_ports     = toset([for s in var.services : s.container_port])
  database_port     = var.db_port
}

module "alb" {
  source = "../alb"

  name                = var.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [module.security.alb_security_group_id]
  certificate_arn     = var.alb_certificate_arn
  deletion_protection = var.alb_deletion_protection
  enable_access_logs  = var.alb_access_logs_enabled

  target_groups = {
    for name, s in var.services : name => {
      port              = s.container_port
      priority          = s.priority
      path_patterns     = s.path_patterns
      host_headers      = s.host_headers
      health_check_path = s.health_check_path
    }
  }
}

module "waf" {
  source = "../waf"
  count  = var.waf_enabled ? 1 : 0

  name               = var.name
  resource_arn       = module.alb.arn
  rate_limit         = var.waf_rate_limit
  log_retention_days = var.log_retention_days
  kms_key_arn        = module.logs_kms_key.arn
}

module "rds" {
  source = "../rds"

  identifier              = var.name
  subnet_ids              = module.vpc.database_subnet_ids
  security_group_ids      = [module.security.database_security_group_id]
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  db_name                 = var.db_name
  master_username         = var.db_master_username
  port                    = var.db_port
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = var.db_deletion_protection
  kms_key_arn             = module.data_kms_key.arn
  log_retention_days      = var.log_retention_days
  log_kms_key_arn         = module.logs_kms_key.arn
}

module "iam_roles" {
  source = "../iam-roles"

  name = var.name
  services = {
    for name, s in var.services : name => { enable_execute_command = s.enable_execute_command }
  }
  secret_arns                   = [module.rds.master_user_secret_arn]
  kms_key_arns                  = [module.data_kms_key.arn]
  execute_command_log_group_arn = module.ecs_cluster.exec_log_group_arn
  execute_command_kms_key_arn   = module.logs_kms_key.arn
}

module "ecs_service" {
  source   = "../ecs-service"
  for_each = var.services

  name                     = "${var.name}-${each.key}"
  cluster_name             = module.ecs_cluster.cluster_name
  image                    = each.value.image
  container_port           = each.value.container_port
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  cpu_architecture         = each.value.cpu_architecture
  readonly_root_filesystem = each.value.readonly_root_filesystem
  enable_execute_command   = each.value.enable_execute_command

  # Los servicios con connect_database reciben la conexión sin guardar credenciales en Terraform
  environment = merge(each.value.environment, each.value.connect_database ? local.database_environment : {})
  secrets     = each.value.connect_database ? local.database_secrets : {}

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.services_security_group_id]
  target_group_arn   = module.alb.target_group_arns[each.key]
  execution_role_arn = module.iam_roles.execution_role_arn
  task_role_arn      = module.iam_roles.task_role_arns[each.key]

  autoscaling = {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
    cpu_target   = each.value.cpu_target
  }

  log_retention_days = var.log_retention_days
  log_kms_key_arn    = module.logs_kms_key.arn

  # El target group debe estar asociado al listener antes de crear el servicio
  depends_on = [module.alb]
}
