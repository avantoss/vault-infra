# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

# Upload config to S3
resource "aws_s3_bucket_object" "object" {
  bucket  = "${ aws_s3_bucket.vault_resources.id }"
  key     = "resources/config/config.hcl"
  content = "${ data.template_file.vault_config.rendered }"
  etag    = "${ md5( data.template_file.vault_config.rendered ) }"

  # Depends on both buckets because we don't want to place until replication is set up
  depends_on = [
    "aws_s3_bucket.vault_resources",
    "aws_s3_bucket.vault_resources_dr"
  ]
}
