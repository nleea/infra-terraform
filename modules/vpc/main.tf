# Define VPC, subnets y route tables

data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394:Se usa un slice fijo de az_count AZs (o availability_zones explícitas); una AZ nueva no altera la selección
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = coalesce(var.availability_zones, slice(data.aws_availability_zones.available.names, 0, var.az_count))

  # Se reservan bloques para el máximo de AZs soportado: aumentar az_count
  # añade subnets nuevas sin recalcular los CIDR de las existentes.
  max_azs = 4
  subnet_cidrs = cidrsubnets(var.cidr_block, concat(
    [for _ in range(local.max_azs) : var.private_subnet_newbits],
    [for _ in range(local.max_azs) : var.public_subnet_newbits],
    [for _ in range(local.max_azs) : var.database_subnet_newbits],
  )...)

  private_cidrs  = { for i, az in local.azs : az => local.subnet_cidrs[i] }
  public_cidrs   = { for i, az in local.azs : az => local.subnet_cidrs[local.max_azs + i] }
  database_cidrs = { for i, az in local.azs : az => local.subnet_cidrs[2 * local.max_azs + i] }

  nat_azs = {
    none       = []
    single     = [local.azs[0]]
    one_per_az = local.azs
  }[var.nat_gateway_mode]

  # AZ del NAT que usa cada subnet privada
  nat_az_for = { for az in local.azs : az => var.nat_gateway_mode == "one_per_az" ? az : local.azs[0] }
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

# Sin reglas: bloquea todo el tráfico del security group por defecto
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-default-deny" }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "public" {
  for_each = local.public_cidrs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_cidrs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_subnet" "database" {
  for_each = local.database_cidrs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${var.name}-database-${each.key}"
    Tier = "database"
  }
}

# ---------------------------------------------------------------------------
# Salida a internet
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = var.name }
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = { Name = "${var.name}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = { Name = "${var.name}-nat-${each.key}" }
}

# ---------------------------------------------------------------------------
# Route tables
# ---------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Una tabla por AZ: cambiar nat_gateway_mode solo cambia el destino de la ruta
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-private-${each.key}" }
}

resource "aws_route" "private_nat" {
  for_each = length(local.nat_azs) > 0 ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[local.nat_az_for[each.key]].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Subnets de base de datos aisladas: sin ruta a internet
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-database" }
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}
