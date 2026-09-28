# Variables de entrada del bootstrap dev

variable "project" {
  description = "Nombre del proyecto, usado como prefijo de recursos y en tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project debe ir en minúsculas, empezar por letra y tener entre 2 y 21 caracteres (a-z, 0-9, -)."
  }
}

variable "environment" {
  description = "Nombre del entorno."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
}

variable "aws_region" {
  description = "Región AWS donde se despliega el entorno."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region debe ser un código de región válido, p. ej. us-east-1."
  }
}

variable "aws_account_id" {
  description = "ID de la cuenta AWS del entorno. El provider rechaza cualquier otra cuenta."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id debe tener 12 dígitos."
  }
}

variable "aws_profile" {
  description = "Perfil local de AWS CLI. Dejar en null en CI (credenciales por OIDC)."
  type        = string
  default     = null
}

variable "assume_role_arn" {
  description = "ARN del rol que asume el provider. Null usa las credenciales del entorno tal cual."
  type        = string
  default     = null

  validation {
    condition     = var.assume_role_arn == null || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", var.assume_role_arn))
    error_message = "assume_role_arn debe ser un ARN de rol IAM válido."
  }
}

variable "owner" {
  description = "Equipo o persona responsable del entorno."
  type        = string
}

variable "cost_center" {
  description = "Centro de costos para imputación de gastos."
  type        = string
}

variable "repository" {
  description = "Repositorio que gestiona esta infraestructura (org/repo)."
  type        = string
}

variable "additional_tags" {
  description = "Tags extra aplicados a todos los recursos. No pueden sobrescribir los tags obligatorios."
  type        = map(string)
  default     = {}
}

variable "create_github_oidc_provider" {
  description = "Crea el OIDC provider de GitHub. Poner false si ya existe en la cuenta."
  type        = bool
  default     = true
}

variable "plan_trusted_principal_arns" {
  description = "Principales IAM humanos que pueden asumir el rol de plan (con MFA)."
  type        = list(string)
  default     = []
}

variable "apply_trusted_principal_arns" {
  description = "Principales IAM humanos que pueden asumir el rol de apply (con MFA)."
  type        = list(string)
  default     = []
}

variable "github_oidc_subject_prefix" {
  description = "Prefijo del claim 'sub' de GitHub OIDC. Null usa repo:<org>/<repo>."
  type        = string
  default     = null
}
