# VPC endpoints: gateway de S3 e interface opcionales

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    [aws_route_table.database.id],
  )

  tags = { Name = "${var.name}-s3" }
}

resource "aws_security_group" "endpoints" {
  # checkov:skip=CKV2_AWS_5:Se crea solo si hay interface endpoints y se asocia a todos ellos
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  name        = "${var.name}-vpc-endpoints"
  description = "HTTPS desde la VPC hacia los interface endpoints"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name}-vpc-endpoints" }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS desde la VPC"
  cidr_ipv4         = aws_vpc.this.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.endpoints[0].id]

  tags = { Name = "${var.name}-${each.value}" }
}
