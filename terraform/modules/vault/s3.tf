# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

resource "aws_s3_bucket" "vault_resources" {
  bucket        = var.vault_resources_bucket_name
  force_destroy = true

  tags = merge(
    { "Name" = var.vault_resources_bucket_name },
    var.tags,
  )
}

resource "aws_s3_bucket_policy" "vault_resources" {
  bucket = aws_s3_bucket.vault_resources.id
  policy = data.aws_iam_policy_document.s3_vault_resources_bucket_policy.json
}

resource "aws_s3_bucket_acl" "vault_resources" {
  bucket = aws_s3_bucket.vault_resources.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "vault_resources" {
  bucket = aws_s3_bucket.vault_resources.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "vault_resources" {
  bucket = aws_s3_bucket.vault_resources.id

  target_bucket = var.vault_resources_bucket_name
  target_prefix = "logs/s3_access_logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_resources_logs" {
  bucket = aws_s3_bucket.vault_resources.bucket

  rule {
    id     = "vault-logs-s3-lifecycle-rule"
    status = "Enabled"
    prefix = "logs/"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      days = var.vault_logs_retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_resources_resources" {
  bucket = aws_s3_bucket.vault_resources.bucket

  rule {
    id     = "vault-resources-s3-lifecycle-rule"
    status = "Enabled"
    prefix = "resources/"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "vault_resources" {
  bucket = aws_s3_bucket.vault_resources.bucket

  role = aws_iam_role.s3_vault_resources_replicaton_role.arn

  rule {
    id     = "replicate-vault-resources"
    status = "Enabled"
    prefix = "resources/"

    destination {
      bucket        = aws_s3_bucket.vault_resources_dr.arn
      storage_class = "STANDARD"
    }
  }

  # must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.vault_resources]
}

resource "aws_s3_bucket" "vault_resources_dr" {
  provider = aws.dr

  bucket        = "${var.vault_resources_bucket_name}-dr"
  force_destroy = true

  tags = merge(
    { "Name" = var.vault_resources_bucket_name },
    var.tags,
  )
}

resource "aws_s3_bucket_versioning" "vault_resources_dr" {
  bucket = aws_s3_bucket.vault_resources_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_resources_dr" {
  bucket = aws_s3_bucket.vault_resources_dr.bucket

  rule {
    id     = "vault-resources-s3-lifecycle-rule"
    status = "Enabled"
    prefix = "resources/"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket" "vault_data" {
  bucket        = var.vault_data_bucket_name
  force_destroy = true

  tags = merge(
    { "Name" = var.vault_data_bucket_name },
    var.tags,
  )
}

resource "aws_s3_bucket_versioning" "vault_data" {
  bucket = aws_s3_bucket.vault_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_data" {
  bucket = aws_s3_bucket.vault_data.bucket

  rule {
    id     = "vault-data-s3-lifecycle-rule"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "vault_data" {
  bucket = aws_s3_bucket.vault_data.bucket

  role = aws_iam_role.s3_vault_data_replicaton_role.arn

  rule {
    id     = "replicate-vault-data"
    status = "Enabled"
    prefix = ""

    destination {
      bucket        = aws_s3_bucket.vault_data_dr.arn
      storage_class = "STANDARD"
    }
  }

  # must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.vault_data]
}

resource "aws_s3_bucket" "vault_data_dr" {
  provider = aws.dr

  bucket        = "${var.vault_data_bucket_name}-dr"
  force_destroy = true

  tags = merge(
    { "Name" = var.vault_data_bucket_name },
    var.tags,
  )
}

resource "aws_s3_bucket_versioning" "vault_data_dr" {
  bucket = aws_s3_bucket.vault_data_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_data_dr" {
  bucket = aws_s3_bucket.vault_data_dr.bucket

  rule {
    id     = "vault-data-s3-lifecycle-rule"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
