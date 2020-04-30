curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request LIST \
    $VAULT_ADDR/v1/auth/ldap/users
