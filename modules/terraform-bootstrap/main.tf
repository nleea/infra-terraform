# Backend de estado remoto, OIDC de GitHub y roles IAM que usa Terraform por entorno

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.region

  terraform_role_path = "/terraform/"
  iam_arn_prefix      = "arn:${local.partition}:iam::${local.account_id}"

  state_bucket_name = "${local.name_prefix}-tfstate-${local.account_id}"
  lock_table_name   = "${local.name_prefix}-tflock"

  github_oidc_url      = "token.actions.githubusercontent.com"
  github_oidc_provider = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn

  github_sub_prefix = coalesce(var.github_oidc_subject_prefix, "repo:${var.github_repository}")

  plan_oidc_subjects = coalesce(var.plan_oidc_subjects, [
    "${local.github_sub_prefix}:pull_request",
    "${local.github_sub_prefix}:ref:refs/heads/main",
  ])
  apply_oidc_subjects = coalesce(var.apply_oidc_subjects, ["${local.github_sub_prefix}:environment:${var.environment}"])
}
