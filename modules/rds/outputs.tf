# Outputs del módulo rds

output "identifier" {
  description = "Identificador de la instancia."
  value       = aws_db_instance.this.identifier
}

output "arn" {
  description = "ARN de la instancia."
  value       = aws_db_instance.this.arn
}

output "address" {
  description = "Hostname de conexión."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Puerto de conexión."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nombre de la base de datos inicial."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "Secret (JSON con username y password) gestionado por RDS."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
