# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

# Returns the account ID that is calling the terraform
data "aws_caller_identity" "current" {}

# Returns the Account ID of the AWS account
# that manages the load balancers for our region
data "aws_elb_service_account" "elb_sa" {}

data "template_file" "userdata" {
  template = "${ file( "${path.module}/files/userdata.sh" ) }"

  vars {
    name_prefix                 = "${ var.name_prefix }"
    region                      = "${ var.region }"
    vault_resources_bucket_name = "${ aws_s3_bucket.vault_resources.id }"
    vault_data_bucket_name      = "${ aws_s3_bucket.vault_data.id }"
  }
}

data "template_file" "vault_config" {
  template = "${ file( "${path.module}/files/config.hcl" ) }"

  vars {
    name_prefix            = "${ var.name_prefix }"
    region                 = "${ var.region }"
    vault_dns_address      = "${ var.vault_dns_address }"
    vault_data_bucket_name = "${ aws_s3_bucket.vault_data.id }"
    dynamodb_table_name    = "${ var.dynamodb_table_name }"
  }
}

# This block converts a standard map of tags to a list of maps of tags for ASGs
data "null_data_source" "asg_tags" {
  count = "${ length( keys( var.tags ) ) }"

  inputs = {
    key                 = "${ element( keys( var.tags ), count.index ) }"
    value               = "${ element( values( var.tags ), count.index ) }"
    propagate_at_launch = true
  }
}
