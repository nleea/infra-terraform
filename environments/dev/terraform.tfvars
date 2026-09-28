# Valores de variables del entorno dev (prueba de pipeline)
project        = "simonmovi"
environment    = "dev"
aws_region     = "us-east-2"
aws_account_id = "223703743244"

owner       = "platform-team"
cost_center = "simonmovi-dev"
repository  = "nleea/infra-terraform"

# Red: 2 AZs y un solo NAT para reducir costo en dev
vpc_cidr                = "10.10.0.0/16"
az_count                = 2
nat_gateway_mode        = "single"
vpc_interface_endpoints = []

log_retention_days = 30

# ECS: 1 tarea on-demand garantizada por servicio y el resto en Spot
ecs_container_insights = "enabled"
ecs_capacity_provider_strategy = [
  { capacity_provider = "FARGATE", weight = 0, base = 1 },
  { capacity_provider = "FARGATE_SPOT", weight = 1 },
]

# ALB: sin certificado de momento (solo HTTP). Al tener dominio, poner el ARN de ACM.
alb_certificate_arn     = null
alb_ingress_cidrs       = ["0.0.0.0/0"]
alb_deletion_protection = false

# WAF activo también en dev para validar las reglas antes de prod
waf_enabled    = true
waf_rate_limit = 1000

# Base de datos: instancia pequeña y sin Multi-AZ para reducir costo en dev
db_engine_version        = "16"
db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50
db_name                  = "simonmovi"
db_master_username       = "simonmovi_admin"
db_multi_az              = false
db_backup_retention_days = 0 # Free plan de AWS: no admite backups automáticos; entorno temporal
db_deletion_protection   = false

# Servicios ECS
services = {
  api = {
    image             = "public.ecr.aws/nginx/nginx:stable-alpine"
    container_port    = 80
    priority          = 100
    path_patterns     = ["/*"]
    health_check_path = "/"
    connect_database  = true

    # nginx necesita escribir en /var/cache; una app propia debería usar true
    readonly_root_filesystem = false
    enable_execute_command   = true

    min_capacity = 1
    max_capacity = 2
  }
}
