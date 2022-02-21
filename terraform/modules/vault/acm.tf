# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

resource "aws_acm_certificate" "acm" {
  count             = var.alb_certificate_arn == "" ? 1 : 0
  domain_name       = local.plain_domain
  validation_method = "DNS"

  tags = merge(
    { "Name" = var.name_prefix },
    var.tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_acm_validation" {
  for_each = var.alb_certificate_arn == "" ? {
    for dvo in aws_acm_certificate.acm[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  name    = each.value.name
  type    = each.value.type
  zone_id = var.zone_id
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "acm_validation" {
  count                   = var.alb_certificate_arn == "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.acm[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dns_acm_validation : record.fqdn]
}
