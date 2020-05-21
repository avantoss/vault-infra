curl \
    --header "X-Vault-Token: $(vault print token)" \
    --request LIST \
    $VAULT_ADDR/v1/sys/host-info
