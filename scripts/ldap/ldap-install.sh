dir=$(dirname $0)
secrets=$dir/../../terraform/.secrets/vault

password=$(cat $secrets/vault_ad.pwd)
rootca=$secrets/active-directory-root.pem

base="OU=active-director,DC=active-directory,DC=infra,DC=tstllc,DC=net" 

vault auth enable ldap
set -x
vault write auth/ldap/config \
    url="ldap://active-directory.infra.tstllc.net" \
    userattr="cn" \
    userdn="OU=Users,$base" \
    groupdn="OU=Groups,$base" \
    groupfilter="(&(member={{.UserDN}})(objectClass=group))" \
    groupattr="cn" \
    binddn="CN=vault,OU=Users,$base" \
    bindpass="$password" \
    certificate=@$rootca \
    insecure_tls=true \
    starttls=true
