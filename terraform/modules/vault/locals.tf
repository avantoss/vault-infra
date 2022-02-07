# The MIT License (MIT)
# Copyright (c) 2014-2022 Avant, Sean Lingren

locals {
  plain_domain = replace(element(split(":", var.vault_dns_address), 1), "////", "")
}
