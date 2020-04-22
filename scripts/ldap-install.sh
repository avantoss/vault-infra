if [[ -z $1 ]] ; then
    echo "Usage: $0 <vault AD password>"
    exit 1
fi

password="$1"

base="OU=active-director,DC=active-directory,DC=infra,DC=tstllc,DC=net" 

vault auth enable ldap
vault write auth/ldap/config \
    url="ldap://active-directory.infra.tstllc.net" \
    userattr="cn" \
    userdn="OU=Users,$base" \
    groupdn="OU=Groups,$base" \
    groupfilter="(&(member={{.UserDN}})(objectClass=group))" \
    groupattr="cn" \
    binddn="CN=vault,OU=Users,$base" \
    bindpass="$password" \
    insecure_tls=true \
    starttls=true
