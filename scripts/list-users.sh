curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request LIST \
    http://127.0.0.1:8200/v1/auth/ldap/users
