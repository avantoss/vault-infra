
terraform {
  backend "s3" {
    bucket = "tstllc-terraform"
    key    = "infra/vault"
    region = "us-east-1"
  }
}

