# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

resource "aws_route53_record" "www" {
  count   = var.route53_enabled ? 1 : 0
  zone_id = var.zone_id
  name    = local.plain_domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}
