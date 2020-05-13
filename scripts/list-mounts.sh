curl -s \
    --header "X-Vault-Token: $(vault print token)" \
    $VAULT_ADDR/v1/sys/mounts | jq '.'
