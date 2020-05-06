dir=$(dirname $0)
policies=$dir/../../policies

for policy in devops engineers dba support ; do
    vault policy write $policy $policies/${policy}.hcl
done
