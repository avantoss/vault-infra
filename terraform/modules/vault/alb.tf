# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_lb" "alb" {
  name            = "${ replace( var.name_prefix, "_", "-" ) }"
  internal        = true
  security_groups = ["${ aws_security_group.alb.id }"]
  subnets         = ["${ var.alb_subnets }"]

  access_logs {
    enabled = true
    bucket  = "${ aws_s3_bucket.vault_resources.id }"
    prefix  = "logs/alb_access_logs"
  }

  tags = "${ merge(
    map("Name", "${ var.name_prefix }"),
    var.tags ) }"
}

# This block redirects HTTP requests to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = "${ aws_lb.alb.arn }"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${ aws_lb.alb.arn }"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-2018-06"
  certificate_arn   = "${ var.alb_certificate_arn }"

  default_action {
    target_group_arn = "${ aws_lb_target_group.tg.arn }"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${ replace( var.name_prefix, "_", "-" ) }"
  port     = "8200"
  protocol = "HTTPS"
  vpc_id   = "${ var.vpc_id }"

  deregistration_delay = "10"

  # /sys/health will return 200 only if the vault instance
  # is the leader. Meaning there will only ever be one healthy
  # instance, but a failure will cause a new instance to
  # be healthy automatically. This healthceck path prevents
  # unnecessary redirect loops by not sending traffic to
  # followers, which always just route traffic to the master
  health_check {
    path                = "/v1/sys/health"
    port                = "8200"
    protocol            = "HTTPS"
    interval            = "5"
    timeout             = "3"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    matcher             = "200"
  }

  tags = "${ merge(
    map("Name","${ var.name_prefix }"),
    var.tags ) }"
}
