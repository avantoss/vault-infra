dir=$(dirname $0)

function usage {
    echo "Usage: $exe -d <database> -r <role> -t <ttl> -m <max-ttl> [-x <prefix>]"
}

database=""
role=""
ttl="1h"
max_ttl="24h"
prefix=""

while getopts ":d:r:t:m:x:" opt; do
    case $opt in
        d) 
            database="$OPTARG"
            ;;
        r) 
            role="$OPTARG"
            ;;
        t)
            ttl="$OPTARG"
            ;;
        m)
            max_ttl="$OPTARG"
            ;;
        x)
            prefix="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;; 
    
        :)
            echo "Option -$OPTARG requires an argument" >&2
            ;;
    esac 
done

shift $((OPTIND-1))

if [[ -z $database || -z $role ]] ; then
    usage
    exit 1
fi

full_role="${database}-${role}"
if [[ -n $prefix ]] ; then
    full_role="${prefix}-${full_role}"
fi

set -x
vault write database/roles/${full_role} \
    db_name=$database \
    creation_statements=@$dir/roles/${role}.role \
    default_ttl="$ttl" \
    max_ttl="$max_ttl"
