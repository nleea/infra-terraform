# Variables de entrada del módulo iam-roles

variable "name" {
  description = "Prefijo de los roles (p. ej. simonmovi-dev). Debe coincidir con el prefijo que permite el rol de apply."
  type        = string
}

variable "services" {
  description = "Servicios ECS que necesitan rol de tarea. policy_json añade permisos propios de la aplicación."
  type = map(object({
    enable_execute_command = optional(bool, false)
    policy_json            = optional(string)
  }))
}

variable "secret_arns" {
  description = "Secrets de Secrets Manager que el rol de ejecución inyecta en los contenedores."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "Claves KMS con las que están cifrados esos secrets."
  type        = list(string)
  default     = []
}

variable "execute_command_log_group_arn" {
  description = "Log group donde se auditan las sesiones de ECS Exec."
  type        = string
  default     = null
}

variable "execute_command_kms_key_arn" {
  description = "Clave KMS que cifra las sesiones de ECS Exec."
  type        = string
  default     = null
}
