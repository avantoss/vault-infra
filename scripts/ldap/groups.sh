dir=$(dirname $0)

. $dir/../vault.inc

for group in $VAULT_DIRECTORY_GROUPS ; do
    vault write auth/ldap/groups/$group policies=$group
done
