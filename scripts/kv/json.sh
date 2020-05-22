if [[ -z $1 ]] ; then
    echo "Usage: $0 <secret path>"
    exit 1
fi

dir=$(dirname $0)
. $dir/../vault.inc

curl -s \
    --header "X-Vault-Token: $(vault print token)" \
    --request GET \
    "$VAULT_ADDR/v1/secret/data/$1" | jq .
