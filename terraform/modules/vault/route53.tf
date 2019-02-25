resource "aws_route53_record" "public_www" {
  count   = "${ var.route53_enabled * var.public_alb == "1" ? 1 : 0 }"
  zone_id = "${ var.zone_id }"
  name    = "${ var.public_domain_name }"
  type    = "A"

  alias {
    name                   = "${ aws_lb.public_alb.dns_name }"
    zone_id                = "${ aws_lb.public_alb.zone_id }"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "private_www" {
  count   = "${ var.route53_enabled ? 1 : 0 }"
  zone_id = "${ var.zone_id }"
  name    = "${ var.private_domain_name }"
  type    = "A"

  alias {
    name                   = "${ aws_lb.alb.dns_name }"
    zone_id                = "${ aws_lb.alb.zone_id }"
    evaluate_target_health = false
  }
}
