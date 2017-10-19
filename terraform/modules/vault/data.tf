# The MIT License (MIT)
#
# Copyright (c) 2014-2017 Avant, Sean Lingren

# Returns the Account ID of the AWS account
# that manages the load balancers for our region
data "aws_elb_service_account" "elb_sa" {}

data "template_file" "userdata" {
  template = "${ file( "${path.module}/files/userdata.sh" ) }"

  vars {
    env                         = "${ var.env }"
    region                      = "${ var.region }"
    vault_resources_bucket_name = "${ aws_s3_bucket.vault_resources.id }"
    vault_data_bucket_name      = "${ aws_s3_bucket.vault_data.id }"
  }
}

data "template_file" "vault_config" {
  template = "${ file( "${path.module}/files/config.hcl" ) }"

  vars {
    env                    = "${ var.env }"
    region                 = "${ var.region }"
    vault_dns_address      = "${ var.vault_dns_address }"
    vault_data_bucket_name = "${ aws_s3_bucket.vault_data.id }"
    dynamodb_table_name    = "${ var.dynamodb_table_name }"
  }
}
