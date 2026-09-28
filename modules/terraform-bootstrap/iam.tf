# Roles IAM de Terraform: plan (solo lectura) y apply (despliegue acotado al proyecto)

locals {
  roles = {
    plan = {
      oidc_subjects      = local.plan_oidc_subjects
      trusted_principals = var.plan_trusted_principal_arns
    }
    apply = {
      oidc_subjects      = local.apply_oidc_subjects
      trusted_principals = var.apply_trusted_principal_arns
    }
  }

  # Recursos IAM de carga de trabajo que el rol de apply puede gestionar
  workload_iam_arns = [
    "${local.iam_arn_prefix}:role/${local.name_prefix}-*",
    "${local.iam_arn_prefix}:policy/${local.name_prefix}-*",
    "${local.iam_arn_prefix}:instance-profile/${local.name_prefix}-*",
  ]
}

# ---------------------------------------------------------------------------
# Trust policies
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  for_each = local.roles

  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_url}:sub"
      values   = each.value.oidc_subjects
    }
  }

  dynamic "statement" {
    for_each = length(each.value.trusted_principals) > 0 ? [1] : []

    content {
      sid     = "HumanOperatorsWithMFA"
      effect  = "Allow"
      actions = ["sts:AssumeRole", "sts:TagSession"]

      principals {
        type        = "AWS"
        identifiers = each.value.trusted_principals
      }

      condition {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

resource "aws_iam_role" "terraform" {
  for_each = local.roles

  name                 = "${local.name_prefix}-terraform-${each.key}"
  path                 = local.terraform_role_path
  description          = "Rol de Terraform (${each.key}) para ${local.name_prefix}"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = var.role_max_session_duration
}

# ---------------------------------------------------------------------------
# Acceso al estado remoto
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "state_access" {
  for_each = local.roles

  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "StateObjects"
    actions   = each.key == "apply" ? ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"] : ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  # plan también necesita escribir el lock
  statement {
    sid       = "StateLock"
    actions   = ["dynamodb:DescribeTable", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.lock.arn]
  }

  statement {
    sid       = "StateEncryption"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.state.arn]
  }
}

resource "aws_iam_role_policy" "state_access" {
  for_each = local.roles

  name   = "terraform-state-access"
  role   = aws_iam_role.terraform[each.key].id
  policy = data.aws_iam_policy_document.state_access[each.key].json
}

# ---------------------------------------------------------------------------
# Rol de plan: lectura de toda la cuenta para poder refrescar el estado
# ---------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.terraform["plan"].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

# ---------------------------------------------------------------------------
# Rol de apply: servicios del stack en la región del entorno + IAM acotado
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "apply" {
  statement {
    sid       = "ManageStackServicesInRegion"
    actions   = [for svc in var.apply_allowed_services : "${svc}:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [local.region]
    }
  }

  # Buckets del proyecto (p. ej. access logs del ALB); el bucket de estado queda protegido abajo
  statement {
    sid     = "ManageProjectBuckets"
    actions = ["s3:*"]
    resources = [
      "arn:${local.partition}:s3:::${local.name_prefix}-*",
      "arn:${local.partition}:s3:::${local.name_prefix}-*/*",
    ]
  }

  statement {
    sid = "ReadIam"
    actions = [
      "iam:Get*",
      "iam:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageWorkloadIam"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:CreateInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:TagInstanceProfile",
      "iam:TagPolicy",
      "iam:TagRole",
      "iam:UntagInstanceProfile",
      "iam:UntagPolicy",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
    ]
    resources = local.workload_iam_arns
  }

  statement {
    sid       = "PassWorkloadRoles"
    actions   = ["iam:PassRole"]
    resources = ["${local.iam_arn_prefix}:role/${local.name_prefix}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = var.pass_role_services
    }
  }

  statement {
    sid       = "CreateServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["${local.iam_arn_prefix}:role/aws-service-role/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = var.service_linked_role_services
    }
  }

  # Impide que el rol se escale privilegios modificando los roles de Terraform
  statement {
    sid         = "DenyTerraformIamTampering"
    effect      = "Deny"
    not_actions = ["iam:Get*", "iam:List*"]
    resources = [
      "${local.iam_arn_prefix}:role${local.terraform_role_path}*",
      "${local.iam_arn_prefix}:policy${local.terraform_role_path}*",
      "${local.iam_arn_prefix}:oidc-provider/${local.github_oidc_url}",
    ]
  }

  # Protege el backend de estado frente a borrados o cambios de política
  statement {
    sid    = "DenyStateBackendTampering"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketAcl",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteBucketOwnershipControls",
      "dynamodb:DeleteTable",
      "dynamodb:UpdateTable",
    ]
    resources = [aws_s3_bucket.state.arn, aws_dynamodb_table.lock.arn]
  }

  # Las versiones antiguas del estado son la copia de seguridad: no se pueden borrar
  statement {
    sid       = "DenyStateHistoryDeletion"
    effect    = "Deny"
    actions   = ["s3:DeleteObjectVersion", "s3:PutObjectAcl", "s3:PutObjectVersionAcl"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid    = "DenyStateKeyTampering"
    effect = "Deny"
    actions = [
      "kms:DisableKey",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:DeleteAlias",
      "kms:UpdateAlias",
    ]
    resources = [aws_kms_key.state.arn, "arn:${local.partition}:kms:${local.region}:${local.account_id}:alias/${local.name_prefix}-tfstate"]
  }
}

resource "aws_iam_policy" "apply" {
  name        = "${local.name_prefix}-terraform-apply"
  path        = local.terraform_role_path
  description = "Permisos de despliegue de Terraform para ${local.name_prefix}"
  policy      = data.aws_iam_policy_document.apply.json
}

resource "aws_iam_role_policy_attachment" "apply" {
  role       = aws_iam_role.terraform["apply"].name
  policy_arn = aws_iam_policy.apply.arn
}
