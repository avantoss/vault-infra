# The MIT License (MIT)
#
# Copyright (c) 2014-2019 Avant, Sean Lingren

module "vault" {
  source = "../modules/vault"

  # Environment
  name_prefix = "${ var.name_prefix }"
  region      = "${ var.region }"
  dr_region   = "${ var.dr_region }"
  tags        = "${ var.tags }"

  # Route53
  # Route53 support is under a switch `route53_enabled`
  # If enabled and `vault_dns_address` not set, creates a DNS name for internal ALB and sets it as an `api_addr` in the Vault configuration
  route53_enabled     = "${ var.route53_enabled }"
  public_domain_name  = "${ var.public_domain_name }" # Optional. Makes sense only in combination with `public_alb = true`
  private_domain_name = "${ var.private_domain_name }"
  zone_id             = "${ var.zone_id }" # Route53 zone id

  # Networking
  vault_dns_address         = "${ var.vault_dns_address }" # Optional. Defaults to ""
  vpc_id                    = "${ var.vpc_id }"
  alb_subnets               = "${ var.alb_subnets }"
  ec2_subnets               = "${ var.ec2_subnets }"
  alb_allowed_ingress_cidrs = "${ var.alb_allowed_ingress_cidrs }"

  # ALB
  alb_certificate_arn = "${ var.alb_certificate_arn }"

  # Public ALB configuration block.
  # Public ALB is under a switch `public_alb`
  # If enabled creates a public ALB.
  # In combination with `route53_enabled` creates public ALB and Route53 DNS entry for the public ALB
  public_alb                       = "${ var.public_alb }"
  public_alb_allowed_ingress_cidrs = "${ var.public_alb_allowed_ingress_cidrs }"

  # EC2
  ami_id               = "${ var.ami_id }"
  instance_type        = "${ var.instance_type }"
  ssh_key_name         = "${ var.ssh_key_name }"
  asg_min_size         = "${ var.asg_min_size }"
  asg_max_size         = "${ var.asg_max_size }"
  asg_desired_capacity = "${ var.asg_desired_capacity }"

  # S3
  vault_resources_bucket_name = "${ var.vault_resources_bucket_name }"
  vault_data_bucket_name      = "${ var.vault_data_bucket_name }"

  # DynamoDB
  dynamodb_table_name = "${ var.dynamodb_table_name }"
}
