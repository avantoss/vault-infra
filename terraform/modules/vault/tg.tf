# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_alb_target_group" "tg" {
  name     = "vault-tg-${ var.env }"
  port     = "8200"
  protocol = "HTTPS"
  vpc_id   = "${ var.vpc_id }"

  deregistration_delay = "10"

  # /sys/haelth will return 200 only if the vault instance
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
    map(
      "Name",
      "vault-tg-${ var.env }"
    ),
    var.tags ) }"
}
