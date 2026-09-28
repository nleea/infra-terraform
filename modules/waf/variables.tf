# Variables de entrada del módulo waf

variable "name" {
  description = "Nombre del Web ACL y prefijo de sus métricas (p. ej. simonmovi-dev)."
  type        = string
}

variable "resource_arn" {
  description = "Recurso regional protegido (ARN del ALB)."
  type        = string
}

variable "rate_limit" {
  description = "Peticiones máximas por IP en una ventana de 5 minutos antes de bloquear."
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100
    error_message = "rate_limit debe ser al menos 100 (mínimo de AWS WAF)."
  }
}

variable "managed_rule_groups" {
  description = "Reglas gestionadas por AWS. count_only las pone en modo observación; rule_overrides pasa reglas concretas a count."
  type = list(object({
    name           = string
    priority       = number
    count_only     = optional(bool, false)
    rule_overrides = optional(list(string), [])
  }))
  default = [
    { name = "AWSManagedRulesAmazonIpReputationList", priority = 10 },
    { name = "AWSManagedRulesCommonRuleSet", priority = 20 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 30 },
    { name = "AWSManagedRulesSQLiRuleSet", priority = 40 },
  ]
}

variable "log_retention_days" {
  description = "Días de retención de los logs de WAF."
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "Clave KMS del log group (debe permitir su uso a CloudWatch Logs)."
  type        = string
  default     = null
}
