# Define el Application Load Balancer, listeners y target groups

locals {
  https_enabled = var.certificate_arn != null
}

resource "aws_lb" "this" {
  # checkov:skip=CKV2_AWS_28:El Web ACL se asocia desde modules/waf (modules/platform lo activa con waf_enabled)
  name               = var.name
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  idle_timeout               = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []

    content {
      bucket  = aws_s3_bucket.access_logs[0].id
      enabled = true
    }
  }

  depends_on = [aws_s3_bucket_policy.access_logs]
}

resource "aws_lb_target_group" "this" {
  # checkov:skip=CKV_AWS_378:TLS termina en el ALB; el tramo ALB -> tarea va por la red privada de la VPC
  for_each = var.target_groups

  # El nombre de un target group admite 32 caracteres
  name                 = substr("${var.name}-${each.key}", 0, 32)
  vpc_id               = var.vpc_id
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = each.value.deregistration_delay

  health_check {
    path                = each.value.health_check_path
    matcher             = each.value.health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ---------------------------------------------------------------------------
# Listeners
# ---------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_2:HTTP solo sirve tráfico cuando no hay certificado; con certificado redirige a HTTPS
  # checkov:skip=CKV_AWS_103:Ídem: con certificado el tráfico va por el listener HTTPS con TLS 1.2+
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.https_enabled ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = local.https_enabled ? [] : [1]

      content {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.target_groups

  listener_arn = local.https_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  dynamic "condition" {
    for_each = length(each.value.path_patterns) > 0 ? [1] : []

    content {
      path_pattern {
        values = each.value.path_patterns
      }
    }
  }

  dynamic "condition" {
    for_each = length(each.value.host_headers) > 0 ? [1] : []

    content {
      host_header {
        values = each.value.host_headers
      }
    }
  }
}
