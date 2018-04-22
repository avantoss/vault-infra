# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

provider "aws" {
  region              = "${ var.region }"
  allowed_account_ids = ["${ var.aws_account_id }"]
}
