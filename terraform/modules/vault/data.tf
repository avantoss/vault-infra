# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

# Returns the account ID that is calling the terraform
data "aws_caller_identity" "current" {}

# Returns the Account ID of the AWS account
# that manages the load balancers for our region
data "aws_elb_service_account" "elb_sa" {}

data "template_file" "userdata" {
  template = file("${path.module}/files/userdata.sh")

  vars = {
    name_prefix                 = var.name_prefix
    region                      = var.region
    vault_cert_dir              = var.vault_cert_dir
    vault_config_dir            = var.vault_config_dir
    vault_resources_bucket_name = aws_s3_bucket.vault_resources.id
    vault_data_bucket_name      = aws_s3_bucket.vault_data.id
    vault_additional_userdata   = var.vault_additional_userdata
  }
}

data "template_file" "vault_config" {
  template = file("${path.module}/files/config.hcl")

  vars = {
    name_prefix             = var.name_prefix
    region                  = var.region
    vault_cert_dir          = var.vault_cert_dir
    vault_dns_address       = var.vault_dns_address
    vault_data_bucket_name  = aws_s3_bucket.vault_data.id
    dynamodb_table_name     = var.dynamodb_table_name
    vault_kms_seal_key_id   = aws_kms_key.seal.key_id
    vault_additional_config = var.vault_additional_config
  }
}
