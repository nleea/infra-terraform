# Variables de entrada del módulo security

variable "name" {
  description = "Prefijo de nombre de los security groups (p. ej. simonmovi-dev)."
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se crean los security groups."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDRs IPv4 que pueden llegar al ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_listener_ports" {
  description = "Puertos abiertos en el ALB."
  type        = set(number)
  default     = [80, 443]
}

variable "service_ports" {
  description = "Puertos de contenedor de los servicios ECS que recibe tráfico desde el ALB."
  type        = set(number)
}

variable "service_egress_cidrs" {
  description = "Destinos HTTPS permitidos desde los servicios (ECR, APIs de AWS, terceros)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "database_port" {
  description = "Puerto de la base de datos accesible desde los servicios."
  type        = number
  default     = 5432
}
