# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_alb" "alb" {
  name            = "vault-alb-${ var.env }"
  internal        = true
  security_groups = ["${ aws_security_group.vault_sg_in_alb.id }"]
  subnets         = "${ var.alb_subnets }"

  access_logs {
    enabled = true
    bucket  = "${ aws_s3_bucket.vault_resources.id }"
    prefix  = "logs/alb_access_logs"
  }

  tags = "${ merge(
    map(
      "Name",
      "vault-alb"
    ),
    var.tags ) }"
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = "${ aws_alb.alb.arn }"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${ var.alb_certificate_arn }"

  default_action {
    target_group_arn = "${ aws_alb_target_group.tg.arn }"
    type             = "forward"
  }
}
