# Variables de entrada del módulo kms-key

variable "name" {
  description = "Nombre de la clave; se publica como alias/<name>."
  type        = string
}

variable "description" {
  description = "Descripción de la clave."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Días de espera antes de borrar la clave."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days debe estar entre 7 y 30."
  }
}

variable "allow_cloudwatch_logs" {
  description = "Permite a CloudWatch Logs de esta cuenta y región usar la clave para cifrar log groups."
  type        = bool
  default     = false
}
