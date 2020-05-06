dir=$(dirname $0)
. $dir/../vault.inc

if [[ -z $VAULT_USER ]] ; then
    echo "Export VAULT_USER to your full user name in Okta/LDAP"
    exit 1
fi

if ! which vault > /dev/null ; then
    echo "Could not find vault. Download from here: https://www.vaultproject.io/downloads"
    exit 1
fi

result=$(vault login -method=ldap username="$VAULT_USER")
token=$(echo "$result" | awk '
    /^token[    ]/ {
        print( $2 )
    }
')

echo "$result" 

if [[ -n $token ]] ; then
    echo ""
    echo "export VAULT_TOKEN=$token"
fi
