# Variables de entrada del módulo rds

variable "identifier" {
  description = "Identificador de la instancia RDS y prefijo de sus recursos (p. ej. simonmovi-dev)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets aisladas de base de datos (mínimo 2 AZs)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups de la instancia."
  type        = list(string)
}

variable "engine_version" {
  description = "Versión de PostgreSQL. Con solo la versión mayor (p. ej. \"16\") AWS aplica las menores automáticamente."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Tipo de instancia."
  type        = string
}

variable "allocated_storage" {
  description = "Almacenamiento inicial en GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Límite de autoescalado de almacenamiento en GiB (0 lo desactiva)."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Nombre de la base de datos inicial."
  type        = string
}

variable "master_username" {
  description = "Usuario administrador. La contraseña la genera y rota RDS en Secrets Manager."
  type        = string
}

variable "port" {
  description = "Puerto de PostgreSQL."
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Réplica síncrona en otra AZ (alta disponibilidad)."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Días de retención de backups automáticos."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Protege la instancia contra borrado."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Clave KMS para almacenamiento, Performance Insights y el secret del usuario administrador."
  type        = string
}

variable "monitoring_interval" {
  description = "Segundos entre métricas de Enhanced Monitoring (0 lo desactiva)."
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval debe ser 0, 1, 5, 10, 15, 30 o 60."
  }
}

variable "performance_insights_retention_period" {
  description = "Días de retención de Performance Insights (7 es gratuito)."
  type        = number
  default     = 7
}

variable "cloudwatch_logs_exports" {
  description = "Logs de PostgreSQL exportados a CloudWatch."
  type        = set(string)
  default     = ["postgresql", "upgrade"]
}

variable "log_retention_days" {
  description = "Días de retención de los logs exportados."
  type        = number
  default     = 365
}

variable "log_kms_key_arn" {
  description = "Clave KMS de los log groups (debe permitir su uso a CloudWatch Logs)."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Parámetros adicionales del parameter group (nombre => valor)."
  type        = map(string)
  default     = {}
}

variable "apply_immediately" {
  description = "Aplica cambios en el momento en vez de en la ventana de mantenimiento."
  type        = bool
  default     = false
}
