# The MIT License (MIT)
#
# Copyright (c) 2014-2019 Avant, Sean Lingren

####################################
## Certificate for private domain ##
####################################
resource "aws_acm_certificate" "private_acm" {
  count             = "${ var.route53_enabled ? 1 : 0 }"
  domain_name       = "${ var.private_domain_name }"
  validation_method = "DNS"

  tags = "${ merge(
    map("Name", "${ var.name_prefix }_private"),
    var.tags ) }"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_route53_record.private_www"]
}

resource "aws_route53_record" "private_acm_validation" {
  name    = "${ aws_acm_certificate.private_acm.domain_validation_options.0.resource_record_name }"
  type    = "${ aws_acm_certificate.private_acm.domain_validation_options.0.resource_record_type }"
  zone_id = "${ var.zone_id }"
  records = ["${ aws_acm_certificate.private_acm.domain_validation_options.0.resource_record_value }"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "private_acm_validation" {
  certificate_arn         = "${ aws_acm_certificate.private_acm.arn }"
  validation_record_fqdns = ["${ aws_route53_record.private_acm_validation.fqdn }"]
}

####################################
## Certificate for public domain ###
####################################
resource "aws_acm_certificate" "public_acm" {
  count             = "${ var.route53_enabled * var.public_alb == "1" ? 1 : 0 }"
  domain_name       = "${ var.public_domain_name }"
  validation_method = "DNS"

  tags = "${ merge(
    map("Name", "${ var.name_prefix }-public"),
    var.tags ) }"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_route53_record.public_www"]
}

resource "aws_route53_record" "public_acm_validation" {
  name    = "${ aws_acm_certificate.public_acm.domain_validation_options.0.resource_record_name }"
  type    = "${ aws_acm_certificate.public_acm.domain_validation_options.0.resource_record_type }"
  zone_id = "${ var.zone_id }"
  records = ["${ aws_acm_certificate.public_acm.domain_validation_options.0.resource_record_value }"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "public_acm_validation" {
  certificate_arn         = "${ aws_acm_certificate.public_acm.arn }"
  validation_record_fqdns = ["${ aws_route53_record.public_acm_validation.fqdn }"]
}
