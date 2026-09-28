# Variables de entrada del módulo ecs-cluster

variable "name" {
  description = "Nombre del cluster ECS (p. ej. simonmovi-dev)."
  type        = string
}

variable "container_insights" {
  description = "Nivel de Container Insights: enhanced, enabled o disabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enhanced", "enabled", "disabled"], var.container_insights)
    error_message = "container_insights debe ser enhanced, enabled o disabled."
  }
}

variable "capacity_providers" {
  description = "Capacity providers de Fargate asociados al cluster."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = alltrue([for cp in var.capacity_providers : contains(["FARGATE", "FARGATE_SPOT"], cp)])
    error_message = "capacity_providers solo admite FARGATE y FARGATE_SPOT."
  }
}

variable "default_capacity_provider_strategy" {
  description = "Estrategia por defecto para los servicios que no definan la suya. base = tareas mínimas en ese provider; weight = reparto del resto."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, 0)
  }))
  default = [{ capacity_provider = "FARGATE", weight = 1 }]
}

variable "kms_key_arn" {
  description = "Clave KMS para cifrar las sesiones de ECS Exec y su log group. La clave debe permitir su uso a CloudWatch Logs."
  type        = string
}

variable "log_retention_days" {
  description = "Días de retención del log group de ECS Exec."
  type        = number
  default     = 365
}
