if [[ -z $1 ]] ; then
    echo "Usage: $0 <lease id>"
    exit 1
fi
lease=$1

curl -s \
    --header "X-Vault-Token: $(vault print token)" \
    --request PUT \
    --data "{ \"lease_id\": \"$lease\" }" \
    $VAULT_ADDR/v1/sys/leases/lookup | jq '.'
