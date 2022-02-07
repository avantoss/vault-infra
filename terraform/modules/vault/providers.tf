# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
