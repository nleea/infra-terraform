# Define los security groups: ALB -> servicios ECS -> base de datos, con mínimo privilegio

locals {
  alb_ingress = {
    for pair in setproduct(var.alb_ingress_cidrs, var.alb_listener_ports) :
    "${pair[0]}-${pair[1]}" => { cidr = pair[0], port = pair[1] }
  }
  service_egress_https = toset(var.service_egress_cidrs)
}

resource "aws_security_group" "alb" {
  # checkov:skip=CKV2_AWS_5:Se asocia al ALB en el módulo alb
  name        = "${var.name}-alb"
  description = "Application Load Balancer de ${var.name}"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-alb" }
}

resource "aws_security_group" "services" {
  # checkov:skip=CKV2_AWS_5:Se asocia a los servicios en el módulo ecs-service
  name        = "${var.name}-services"
  description = "Servicios ECS de ${var.name}"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-services" }
}

resource "aws_security_group" "database" {
  # checkov:skip=CKV2_AWS_5:Se asocia a la instancia en el módulo rds
  name        = "${var.name}-database"
  description = "Base de datos de ${var.name}"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-database" }
}

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb" {
  # checkov:skip=CKV_AWS_260:ALB público; el puerto 80 solo redirige a HTTPS cuando hay certificado
  for_each = local.alb_ingress

  security_group_id = aws_security_group.alb.id
  description       = "Trafico al listener ${each.value.port}"
  cidr_ipv4         = each.value.cidr
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
}

resource "aws_vpc_security_group_egress_rule" "alb_to_services" {
  for_each = { for port in var.service_ports : tostring(port) => port }

  security_group_id            = aws_security_group.alb.id
  description                  = "Hacia los servicios ECS en el puerto ${each.value}"
  referenced_security_group_id = aws_security_group.services.id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
}

# ---------------------------------------------------------------------------
# Servicios ECS
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "services_from_alb" {
  for_each = { for port in var.service_ports : tostring(port) => port }

  security_group_id            = aws_security_group.services.id
  description                  = "Desde el ALB en el puerto ${each.value}"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
}

resource "aws_vpc_security_group_egress_rule" "services_https" {
  for_each = local.service_egress_https

  security_group_id = aws_security_group.services.id
  description       = "HTTPS saliente (ECR, APIs de AWS)"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "services_to_database" {
  security_group_id            = aws_security_group.services.id
  description                  = "Hacia la base de datos"
  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = var.database_port
  to_port                      = var.database_port
}

# ---------------------------------------------------------------------------
# Base de datos: solo entrada desde los servicios, sin salida
# ---------------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "database_from_services" {
  security_group_id            = aws_security_group.database.id
  description                  = "Desde los servicios ECS"
  referenced_security_group_id = aws_security_group.services.id
  ip_protocol                  = "tcp"
  from_port                    = var.database_port
  to_port                      = var.database_port
}
