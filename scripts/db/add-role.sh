dir=$(dirname $0)

if [[ -z $2 ]] ; then
    echo "Usage: $0 <database> <role> [ttl] [max_ttl]" 
    exit 1
fi

database=$1
role=$2
ttl=${3:-"1h"}
max_ttl=${4:-"24h"}

set -x
vault write database/roles/${database}-${role} \
    db_name=$database \
    creation_statements=@$dir/roles/${role}.role \
    default_ttl="$ttl" \
    max_ttl="$max_ttl"
