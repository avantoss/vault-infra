# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

module "vault" {
  source = "../modules/vault"

  # Environment
  name_prefix = var.name_prefix
  region      = var.region
  dr_region   = var.dr_region
  tags        = var.tags

  # Route53
  route53_enabled = var.route53_enabled
  zone_id         = var.zone_id # Route53 zone id

  # Networking
  vault_dns_address         = var.vault_dns_address
  vpc_id                    = var.vpc_id
  alb_subnets               = var.alb_subnets
  ec2_subnets               = var.ec2_subnets
  alb_allowed_ingress_cidrs = var.alb_allowed_ingress_cidrs

  # ALB
  alb_certificate_arn = var.alb_certificate_arn # Would be used on ALB. If not specified, certificate would be requested via AWS ACM

  # EC2
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  ssh_key_name         = var.ssh_key_name
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  # S3
  vault_resources_bucket_name = var.vault_resources_bucket_name
  vault_data_bucket_name      = var.vault_data_bucket_name

  # DynamoDB
  dynamodb_table_name = var.dynamodb_table_name
}
