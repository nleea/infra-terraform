# Outputs del módulo vpc

output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Zonas de disponibilidad usadas, en orden."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas (ALB), en el orden de azs."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas (ECS), en el orden de azs."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "database_subnet_ids" {
  description = "IDs de las subnets de base de datos (RDS), en el orden de azs."
  value       = [for az in local.azs : aws_subnet.database[az].id]
}

output "private_route_table_ids" {
  description = "IDs de las route tables privadas, en el orden de azs."
  value       = [for az in local.azs : aws_route_table.private[az].id]
}

output "nat_public_ips" {
  description = "IPs públicas de salida de los NAT gateways (útiles para allowlists externas)."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}
