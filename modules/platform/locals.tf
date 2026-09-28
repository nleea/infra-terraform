# Valores derivados de la plataforma
locals {
  # Conexión a la base de datos inyectada en los servicios con connect_database
  database_environment = {
    DB_HOST = module.rds.address
    DB_PORT = tostring(module.rds.port)
    DB_NAME = module.rds.db_name
  }
  database_secrets = {
    DB_USERNAME = "${module.rds.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
  }
}
