# Define los roles y políticas IAM de ECS: ejecución (compartido) y tarea (uno por servicio)

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  partition     = data.aws_partition.current.partition
  exec_services = { for k, s in var.services : k => s if s.enable_execute_command }
  app_policies  = { for k, s in var.services : k => s.policy_json if s.policy_json != null }
}

data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# ---------------------------------------------------------------------------
# Rol de ejecución: lo usa el agente de ECS para descargar la imagen,
# escribir logs e inyectar secrets. No lo usa la aplicación.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  statement {
    sid       = "ReadInjectedSecrets"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secret_arns
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptInjectedSecrets"
      actions   = ["kms:Decrypt"]
      resources = var.kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  name   = "inject-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

# ---------------------------------------------------------------------------
# Roles de tarea: identidad de la aplicación, uno por servicio
# ---------------------------------------------------------------------------

resource "aws_iam_role" "task" {
  for_each = var.services

  name               = "${var.name}-${each.key}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "execute_command" {
  # checkov:skip=CKV_AWS_356:ssmmessages no admite permisos a nivel de recurso
  # checkov:skip=CKV_AWS_111:ssmmessages no admite permisos a nivel de recurso
  statement {
    sid = "EcsExecChannels"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.execute_command_log_group_arn != null ? [1] : []

    content {
      sid       = "EcsExecAuditLogs"
      actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      resources = ["${var.execute_command_log_group_arn}:*"]
    }
  }

  dynamic "statement" {
    for_each = var.execute_command_log_group_arn != null ? [1] : []

    content {
      sid       = "EcsExecDescribeLogGroups"
      actions   = ["logs:DescribeLogGroups"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.execute_command_kms_key_arn != null ? [1] : []

    content {
      sid       = "EcsExecEncryption"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.execute_command_kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "execute_command" {
  for_each = local.exec_services

  name   = "ecs-exec"
  role   = aws_iam_role.task[each.key].id
  policy = data.aws_iam_policy_document.execute_command.json
}

resource "aws_iam_role_policy" "app" {
  for_each = local.app_policies

  name   = "application"
  role   = aws_iam_role.task[each.key].id
  policy = each.value
}
