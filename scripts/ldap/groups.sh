dir=$(dirname $0)

groups="devops engineers"

for group in $groups ; do
    vault write auth/ldap/groups/$group policies=$group
done
