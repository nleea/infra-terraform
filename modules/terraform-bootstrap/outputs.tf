# Outputs del módulo terraform-bootstrap

output "state_bucket_name" {
  description = "Bucket S3 del estado remoto."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Tabla DynamoDB para el bloqueo del estado."
  value       = aws_dynamodb_table.lock.name
}

output "state_kms_key_arn" {
  description = "Clave KMS que cifra el estado."
  value       = aws_kms_key.state.arn
}

output "github_oidc_provider_arn" {
  description = "ARN del OIDC provider de GitHub."
  value       = local.github_oidc_provider
}

output "plan_role_arn" {
  description = "Rol que asume el workflow de plan."
  value       = aws_iam_role.terraform["plan"].arn
}

output "apply_role_arn" {
  description = "Rol que asume el workflow de apply."
  value       = aws_iam_role.terraform["apply"].arn
}

output "backend_config" {
  description = "Contenido de backend.hcl para 'terraform init -backend-config=backend.hcl'."
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    region         = "${local.region}"
    dynamodb_table = "${aws_dynamodb_table.lock.name}"
    kms_key_id     = "${aws_kms_key.state.arn}"
  EOT
}
