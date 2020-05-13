role="jenkins"

set -x
vault write auth/approle/role/$role \
    secret_id_ttl="" \
    token_num_uses=0 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=0 \
    token_policies=default,builder

vault read auth/approle/role/$role/role-id

vault write -f auth/approle/role/$role/secret-id
