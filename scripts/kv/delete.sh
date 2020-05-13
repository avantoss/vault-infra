if [[ -z $1 ]] ; then
    echo "Usage: $0 <secret>"
    exit 1
fi

secret=$1
shift 1

set -x
vault kv delete "$@" secret/$secret 

