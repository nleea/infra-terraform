# Define el cluster ECS (Fargate) y su configuración de capacidad y ECS Exec

resource "aws_cloudwatch_log_group" "exec" {
  name              = "/aws/ecs/${var.name}/exec"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  # Las sesiones de "aws ecs execute-command" quedan cifradas y auditadas
  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_key_arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.exec.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy

    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for s in var.default_capacity_provider_strategy : contains(var.capacity_providers, s.capacity_provider)
      ])
      error_message = "Cada capacity_provider de la estrategia debe estar en capacity_providers."
    }
  }
}
