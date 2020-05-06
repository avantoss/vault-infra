dir=$(dirname $0)
policies=$dir/../../policies

groups="devops engineers dba support"

for policy in $groups ; do
    vault policy write $policy $policies/${policy}.hcl
done
