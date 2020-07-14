if [[ -z $2 ]] ; then
    echo "Usage: $0 <secret> key=value ..."
    exit 1
fi

secret="$1"
shift

set -x
vault kv put "secret/$secret" "$@"

