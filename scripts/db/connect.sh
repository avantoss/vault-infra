dir=$(dirname $0)
. $dir/../vault.inc

function usage {
    echo "Usage: $exe -d <database> -r <role> [-x <prefix>]"
}

database=""
role=""
prefix=""

while getopts ":d:r:t:m:x:" opt; do
    case $opt in
        d) 
            database="$OPTARG"
            ;;
        r) 
            role="$OPTARG"
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
vault read database/creds/${full_role}
