# Variables de entrada del módulo terraform-bootstrap

variable "project" {
  description = "Nombre del proyecto, usado como prefijo de recursos."
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod)."
  type        = string
}

variable "github_repository" {
  description = "Repositorio de GitHub (org/repo) autorizado a asumir los roles por OIDC."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository debe tener el formato org/repo."
  }
}

variable "create_github_oidc_provider" {
  description = "Crea el OIDC provider de GitHub. Poner false si ya existe en la cuenta (solo puede haber uno)."
  type        = bool
  default     = true
}

variable "github_oidc_subject_prefix" {
  description = "Prefijo del claim 'sub' de GitHub. Null usa repo:<org>/<repo>; con immutable subject: repo:<org>@<owner_id>/<repo>@<repo_id> (gh api repos/<org>/<repo>/actions/oidc/customization/sub)."
  type        = string
  default     = null

  validation {
    condition     = var.github_oidc_subject_prefix == null || can(regex("^repo:[^:*]+$", var.github_oidc_subject_prefix))
    error_message = "github_oidc_subject_prefix debe empezar por 'repo:' y no contener ':' ni comodines."
  }
}

variable "plan_oidc_subjects" {
  description = "Claims 'sub' de GitHub que pueden asumir el rol de plan. Null usa los pull requests y la rama main del repo."
  type        = list(string)
  default     = null
}

variable "apply_oidc_subjects" {
  description = "Claims 'sub' de GitHub que pueden asumir el rol de apply. Null usa el GitHub Environment con el nombre del entorno."
  type        = list(string)
  default     = null
}

variable "plan_trusted_principal_arns" {
  description = "Principales IAM (usuarios/roles humanos) que pueden asumir el rol de plan con MFA."
  type        = list(string)
  default     = []
}

variable "apply_trusted_principal_arns" {
  description = "Principales IAM (usuarios/roles humanos) que pueden asumir el rol de apply con MFA."
  type        = list(string)
  default     = []
}

variable "apply_allowed_services" {
  description = "Prefijos de servicio AWS que el rol de apply puede gestionar en la región del entorno."
  type        = list(string)
  default = [
    "application-autoscaling",
    "acm",
    "cloudwatch",
    "ec2",
    "ecs",
    "elasticloadbalancing",
    "kms",
    "logs",
    "rds",
    "secretsmanager",
    "ssm",
    "wafv2",
  ]
}

variable "pass_role_services" {
  description = "Servicios a los que el rol de apply puede pasar roles IAM del proyecto (iam:PassRole)."
  type        = list(string)
  default = [
    "ecs-tasks.amazonaws.com",
    "ecs.amazonaws.com",
    "monitoring.rds.amazonaws.com",
    # CreateDBInstance evalúa el rol de Enhanced Monitoring con PassedToService = rds.amazonaws.com
    "rds.amazonaws.com",
    "vpc-flow-logs.amazonaws.com",
  ]
}

variable "service_linked_role_services" {
  description = "Servicios para los que el rol de apply puede crear service-linked roles."
  type        = list(string)
  default = [
    "ecs.amazonaws.com",
    "elasticloadbalancing.amazonaws.com",
    "rds.amazonaws.com",
    "ecs.application-autoscaling.amazonaws.com",
    "wafv2.amazonaws.com",
  ]
}

variable "role_max_session_duration" {
  description = "Duración máxima de sesión (segundos) de los roles de Terraform."
  type        = number
  default     = 3600

  validation {
    condition     = var.role_max_session_duration >= 3600 && var.role_max_session_duration <= 43200
    error_message = "role_max_session_duration debe estar entre 3600 y 43200."
  }
}

variable "state_noncurrent_version_retention_days" {
  description = "Días que se conservan las versiones antiguas del estado."
  type        = number
  default     = 90
}

variable "kms_deletion_window_in_days" {
  description = "Ventana de borrado de la clave KMS del estado."
  type        = number
  default     = 30
}

variable "force_destroy_state_bucket" {
  description = "Permite destruir el bucket de estado aunque tenga objetos. Mantener en false."
  type        = bool
  default     = false
}
