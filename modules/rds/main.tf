# Define la instancia RDS PostgreSQL y su subnet group

data "aws_partition" "current" {}

locals {
  major_version = split(".", var.engine_version)[0]

  # Conexiones solo por TLS y registro de sentencias lentas
  parameters = merge({
    "rds.force_ssl"              = "1"
    "log_min_duration_statement" = "1000"
  }, var.parameters)
}

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.subnet_ids
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.identifier}-pg${local.major_version}-"
  family      = "postgres${local.major_version}"

  dynamic "parameter" {
    for_each = local.parameters

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Se crean antes que la instancia para controlar retención y cifrado
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.cloudwatch_logs_exports

  name              = "/aws/rds/instance/${var.identifier}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn
}

data "aws_iam_policy_document" "monitoring_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name               = "${var.identifier}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_trust.json
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV2_AWS_69:rds.force_ssl=1 se fija en aws_db_parameter_group.this (local.parameters)
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  port           = var.port

  db_name                       = var.db_name
  username                      = var.master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  allow_major_version_upgrade         = false
  apply_immediately                   = var.apply_immediately

  backup_retention_period   = var.backup_retention_period
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final"

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = var.performance_insights_retention_period

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports

  depends_on = [aws_cloudwatch_log_group.this]
}
