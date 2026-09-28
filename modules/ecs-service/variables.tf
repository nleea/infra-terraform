# Variables de entrada del módulo ecs-service

variable "name" {
  description = "Nombre del servicio y de su task definition (p. ej. simonmovi-dev-api)."
  type        = string
}

variable "cluster_name" {
  description = "Cluster ECS donde corre el servicio."
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor principal."
  type        = string
  default     = "app"
}

variable "image" {
  description = "Imagen del contenedor (idealmente fijada por digest o tag inmutable)."
  type        = string
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor."
  type        = number
}

variable "cpu" {
  description = "CPU de la tarea en unidades (256 = 0,25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria de la tarea en MiB; debe ser compatible con cpu en Fargate."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "Arquitectura de la imagen: X86_64 o ARM64 (Graviton, más barato)."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture debe ser X86_64 o ARM64."
  }
}

variable "environment" {
  description = "Variables de entorno en claro (nada sensible)."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Variables de entorno sensibles: nombre => ARN de Secrets Manager (admite sufijo :clave-json::)."
  type        = map(string)
  default     = {}
}

variable "readonly_root_filesystem" {
  description = "Monta el sistema de archivos del contenedor en solo lectura."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Subnets privadas de las tareas."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups de las tareas."
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group del ALB al que se registran las tareas."
  type        = string
}

variable "health_check_grace_period" {
  description = "Segundos que se ignoran los health checks del ALB tras arrancar una tarea."
  type        = number
  default     = 60
}

variable "execution_role_arn" {
  description = "Rol de ejecución (descarga de imagen, logs, secrets)."
  type        = string
}

variable "task_role_arn" {
  description = "Rol de la aplicación."
  type        = string
}

variable "enable_execute_command" {
  description = "Permite abrir una shell en los contenedores con ECS Exec."
  type        = bool
  default     = false
}

variable "capacity_provider_strategy" {
  description = "Estrategia propia del servicio. Vacía usa la estrategia por defecto del cluster."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, 0)
  }))
  default = []
}

variable "autoscaling" {
  description = "Número de tareas: arranca con min_capacity y escala por CPU hasta max_capacity."
  type = object({
    min_capacity = number
    max_capacity = number
    cpu_target   = optional(number, 70)
  })
  default = {
    min_capacity = 1
    max_capacity = 2
  }

  validation {
    condition     = var.autoscaling.min_capacity >= 0 && var.autoscaling.max_capacity >= var.autoscaling.min_capacity
    error_message = "autoscaling.max_capacity debe ser >= min_capacity y min_capacity >= 0."
  }
}

variable "log_retention_days" {
  description = "Días de retención de los logs del contenedor."
  type        = number
  default     = 365
}

variable "log_kms_key_arn" {
  description = "Clave KMS del log group del servicio."
  type        = string
  default     = null
}
