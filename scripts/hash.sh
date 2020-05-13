if [[ -z $2 ]] ; then
    echo "Usage: $0 <path> <value>"
    exit 1
fi
path="$1"
value="$2"

set -x
curl -s -XPOST \
    --header "X-Vault-Token: $(vault print token)" \
    -d "{ \"input\": \"$value\" }" \
    $VAULT_ADDR/v1/sys/audit-hash/$path | jq '.'
