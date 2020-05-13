dir=$(dirname $0)
secrets=$dir/../../../terraform/.secrets/vault

rootca=$secrets/active-directory-root.pem

user="vault"
password=$(cat $secrets/vault-ad.pwd)
base="OU=active-director,DC=active-directory,DC=infra,DC=tstllc,DC=net"
userdn="CN=$user,$base" 

set -x
vault write ad/config \
    binddn="$userdn" \
    bindpass="$password" \
    url="ldap://active-directory.infra.tstllc.net" \
    userdn=$base \
    certificate=@$rootca \
    insecure_tls=true \
    starttls=true \
    request_timeout=30s
