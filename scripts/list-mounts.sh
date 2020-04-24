curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/sys/mounts | jq '.'
