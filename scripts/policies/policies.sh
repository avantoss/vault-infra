dir=$(dirname $0)
policies=$dir/../../policies

. $dir/../vault.inc

for policy in $VAULT_GROUPS ; do
    vault policy write $policy $policies/${policy}.hcl
done
