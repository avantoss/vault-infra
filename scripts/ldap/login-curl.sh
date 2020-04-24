if [[ -z $VAULT_USER ]] ; then
    echo "Export VAULT_USER to your full user name in Okta/LDAP"
    exit 1
fi

set -x
vault login -method=ldap -output-curl-string username="$VAULT_USER"

