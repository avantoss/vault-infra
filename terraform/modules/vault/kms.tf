# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

resource "aws_kms_alias" "seal" {
  name          = "alias/${var.name_prefix}/seal"
  target_key_id = aws_kms_key.seal.key_id
}

resource "aws_kms_key" "seal" {
  description = "KMS key used for ${var.name_prefix} seal"

  enable_key_rotation = true

  tags = merge(
    { "Name" = "${var.name_prefix}-seal" },
    var.tags,
  )
}
