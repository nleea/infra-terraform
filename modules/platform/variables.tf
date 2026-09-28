# Variables de entrada del módulo platform

variable "name" {
  description = "Prefijo de todos los recursos (<project>-<environment>). Debe coincidir con el prefijo que permite el rol de apply."
  type        = string
}

# ---------------------------------------------------------------------------
# Red
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR de la VPC del entorno. No debe solaparse con otros entornos si se van a interconectar."
  type        = string
}

variable "az_count" {
  description = "Número de zonas de disponibilidad."
  type        = number
}

variable "nat_gateway_mode" {
  description = "none, single (un NAT compartido) o one_per_az (alta disponibilidad)."
  type        = string
}

variable "vpc_interface_endpoints" {
  description = "Servicios con VPC endpoint de tipo interface (p. ej. ecr.api, ecr.dkr, logs)."
  type        = set(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Observabilidad
# ---------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Días de retención de los log groups del entorno."
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days debe ser un valor admitido por CloudWatch Logs (1, 3, 5, 7, 14, 30, 60, 90, ... 3653)."
  }
}

# ---------------------------------------------------------------------------
# ECS
# ---------------------------------------------------------------------------

variable "ecs_container_insights" {
  description = "Nivel de Container Insights: enhanced, enabled o disabled."
  type        = string
}

variable "ecs_capacity_provider_strategy" {
  description = "Estrategia de capacidad por defecto del cluster."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, 0)
  }))
}

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------

variable "alb_certificate_arn" {
  description = "Certificado ACM del ALB. Null expone solo HTTP."
  type        = string
  default     = null
}

variable "alb_ingress_cidrs" {
  description = "CIDRs que pueden acceder al ALB."
  type        = list(string)
}

variable "alb_deletion_protection" {
  description = "Protege el ALB contra borrado."
  type        = bool
}

variable "alb_access_logs_enabled" {
  description = "Guarda los access logs del ALB en S3."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# WAF
# ---------------------------------------------------------------------------

variable "waf_enabled" {
  description = "Protege el ALB con AWS WAF."
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Peticiones máximas por IP cada 5 minutos."
  type        = number
  default     = 2000
}

# ---------------------------------------------------------------------------
# Base de datos
# ---------------------------------------------------------------------------

variable "db_engine_version" {
  description = "Versión de PostgreSQL."
  type        = string
}

variable "db_instance_class" {
  description = "Tipo de instancia RDS."
  type        = string
}

variable "db_allocated_storage" {
  description = "Almacenamiento inicial en GiB."
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Límite de autoescalado de almacenamiento en GiB."
  type        = number
}

variable "db_name" {
  description = "Nombre de la base de datos inicial."
  type        = string
}

variable "db_master_username" {
  description = "Usuario administrador (la contraseña la gestiona RDS en Secrets Manager)."
  type        = string
}

variable "db_port" {
  description = "Puerto de PostgreSQL."
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Réplica en otra AZ."
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Días de retención de backups."
  type        = number
}

variable "db_deletion_protection" {
  description = "Protege la base de datos contra borrado."
  type        = bool
}

# ---------------------------------------------------------------------------
# Servicios ECS
# ---------------------------------------------------------------------------

variable "services" {
  description = "Servicios ECS del entorno. La clave es el nombre corto del servicio."
  type = map(object({
    image                    = string
    container_port           = number
    priority                 = number
    path_patterns            = optional(list(string), [])
    host_headers             = optional(list(string), [])
    health_check_path        = optional(string, "/")
    cpu                      = optional(number, 256)
    memory                   = optional(number, 512)
    cpu_architecture         = optional(string, "X86_64")
    environment              = optional(map(string), {})
    connect_database         = optional(bool, false)
    enable_execute_command   = optional(bool, false)
    readonly_root_filesystem = optional(bool, true)
    min_capacity             = optional(number, 1)
    max_capacity             = optional(number, 2)
    cpu_target               = optional(number, 70)
  }))

  validation {
    condition     = alltrue([for k in keys(var.services) : can(regex("^[a-z][a-z0-9-]{0,14}$", k))])
    error_message = "Los nombres de servicio deben ir en minúsculas y tener como máximo 15 caracteres (a-z, 0-9, -)."
  }
}
