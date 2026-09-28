# Valores de variables del entorno prod
project        = "simonmovi"
environment    = "prod"
aws_region     = "us-east-1"
aws_account_id = "223703743244"

owner       = "platform-team"
cost_center = "simonmovi-prod"
repository  = "nleea/infra-terraform"

# Red: 3 AZs y un NAT por AZ (si cae una zona, las demás mantienen salida a internet)
vpc_cidr         = "10.20.0.0/16"
az_count         = 3
nat_gateway_mode = "one_per_az"

# Las llamadas a ECR, CloudWatch Logs y Secrets Manager no salen de la red de AWS.
vpc_interface_endpoints = ["ecr.api", "ecr.dkr", "logs", "secretsmanager"]

log_retention_days = 365

# ECS: 2 tareas on-demand garantizadas; lo que escale se reparte 3:1 entre on-demand y Spot
ecs_container_insights = "enhanced"
ecs_capacity_provider_strategy = [
  { capacity_provider = "FARGATE", weight = 3, base = 2 },
  { capacity_provider = "FARGATE_SPOT", weight = 1 },
]

# ALB
# TODO: con dominio propio, emitir un certificado en ACM (us-east-1) y poner su ARN:
# se activa HTTPS con TLS 1.2+ y HTTP pasa a redirigir a HTTPS.
alb_certificate_arn     = null
alb_ingress_cidrs       = ["0.0.0.0/0"]
alb_deletion_protection = true

waf_enabled    = true
waf_rate_limit = 2000

# Base de datos: Multi-AZ, protegida contra borrado y 30 días de backups
db_engine_version        = "16"
db_instance_class        = "db.t4g.medium"
db_allocated_storage     = 50
db_max_allocated_storage = 500
db_name                  = "simonmovi"
db_master_username       = "simonmovi_admin"
db_multi_az              = true
db_backup_retention_days = 30
db_deletion_protection   = true

# Servicios ECS
services = {
  api = {
    image             = "public.ecr.aws/nginx/nginx:stable-alpine"
    container_port    = 80
    priority          = 100
    path_patterns     = ["/*"]
    health_check_path = "/"
    connect_database  = true
    cpu               = 512
    memory            = 1024

    readonly_root_filesystem = false

    # Zero Trust: sin acceso interactivo a los contenedores en producción
    enable_execute_command = false

    min_capacity = 2
    max_capacity = 10
    cpu_target   = 60
  }
}