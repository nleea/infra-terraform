# Variables de entrada del módulo vpc

variable "name" {
  description = "Prefijo de nombre para todos los recursos de red (p. ej. simonmovi-dev)."
  type        = string
}

variable "cidr_block" {
  description = "Rango CIDR de la VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && tonumber(split("/", var.cidr_block)[1]) <= 20
    error_message = "cidr_block debe ser un CIDR IPv4 válido con prefijo /20 o mayor (p. ej. 10.10.0.0/16)."
  }
}

variable "az_count" {
  description = "Número de zonas de disponibilidad a usar (una subnet por tier en cada una)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count debe estar entre 2 y 4."
  }
}

variable "availability_zones" {
  description = "AZs concretas a usar (p. ej. [\"us-east-2a\", \"us-east-2b\"]). Null toma las primeras az_count de la región."
  type        = list(string)
  default     = null

  validation {
    condition     = var.availability_zones == null || length(coalesce(var.availability_zones, [])) == var.az_count
    error_message = "availability_zones debe tener exactamente az_count elementos."
  }
}

variable "private_subnet_newbits" {
  description = "Bits añadidos al prefijo de la VPC para las subnets privadas (ECS). Con /16 y 4 resulta /20."
  type        = number
  default     = 4
}

variable "public_subnet_newbits" {
  description = "Bits añadidos al prefijo de la VPC para las subnets públicas (ALB, NAT). Con /16 y 8 resulta /24."
  type        = number
  default     = 8
}

variable "database_subnet_newbits" {
  description = "Bits añadidos al prefijo de la VPC para las subnets de base de datos. Con /16 y 8 resulta /24."
  type        = number
  default     = 8
}

variable "nat_gateway_mode" {
  description = "none: sin salida a internet desde privadas; single: un NAT compartido (menor costo); one_per_az: un NAT por AZ (alta disponibilidad)."
  type        = string
  default     = "one_per_az"

  validation {
    condition     = contains(["none", "single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode debe ser none, single o one_per_az."
  }
}

variable "enable_s3_gateway_endpoint" {
  description = "Crea el endpoint gateway de S3 (gratuito; evita tráfico por NAT hacia S3/ECR)."
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = "Servicios con VPC endpoint de tipo interface (p. ej. ecr.api, ecr.dkr, logs, secretsmanager). Cada uno tiene costo por hora y AZ."
  type        = set(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Activa VPC Flow Logs hacia CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Tráfico registrado en los flow logs: ACCEPT, REJECT o ALL."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type debe ser ACCEPT, REJECT o ALL."
  }
}

variable "flow_logs_aggregation_interval" {
  description = "Intervalo máximo de agregación de los flow logs en segundos (60 o 600)."
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_aggregation_interval)
    error_message = "flow_logs_aggregation_interval debe ser 60 o 600."
  }
}

variable "log_retention_days" {
  description = "Días de retención del log group de flow logs."
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "Clave KMS para cifrar el log group de flow logs. Null usa el cifrado por defecto de CloudWatch."
  type        = string
  default     = null
}
