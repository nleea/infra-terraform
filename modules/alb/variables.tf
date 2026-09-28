# Variables de entrada del módulo alb

variable "name" {
  description = "Nombre del ALB y prefijo de sus recursos (p. ej. simonmovi-dev)."
  type        = string
}

variable "vpc_id" {
  description = "VPC de los target groups."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets públicas donde se despliega el ALB (mínimo 2 AZs)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups del ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "Certificado ACM para HTTPS. Null expone solo HTTP (útil mientras no hay dominio)."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Política TLS del listener HTTPS."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "deletion_protection" {
  description = "Protege el ALB contra borrado."
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Segundos de inactividad antes de cerrar una conexión."
  type        = number
  default     = 60
}

variable "enable_access_logs" {
  description = "Guarda los access logs del ALB en un bucket S3 propio."
  type        = bool
  default     = true
}

variable "access_logs_retention_days" {
  description = "Días que se conservan los access logs."
  type        = number
  default     = 90
}

variable "force_destroy_access_logs" {
  description = "Permite borrar el bucket de logs aunque tenga objetos."
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Un target group por servicio, con su regla de enrutamiento en el listener."
  type = map(object({
    port                 = number
    priority             = number
    path_patterns        = optional(list(string), [])
    host_headers         = optional(list(string), [])
    health_check_path    = optional(string, "/")
    health_check_matcher = optional(string, "200-399")
    deregistration_delay = optional(number, 30)
  }))

  validation {
    condition     = alltrue([for tg in var.target_groups : length(tg.path_patterns) + length(tg.host_headers) > 0])
    error_message = "Cada target group necesita al menos un path_pattern o host_header."
  }

  validation {
    condition     = length(distinct([for tg in var.target_groups : tg.priority])) == length(var.target_groups)
    error_message = "Las prioridades de los target groups deben ser únicas."
  }
}
