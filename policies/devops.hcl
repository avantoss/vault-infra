path "secret/data/devops" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

path "database/creds/nonprod-*" {
    capabilities = [ "read" ]
}

path "database/creds/prod-*" {
    capabilities = [ "read" ]
}
