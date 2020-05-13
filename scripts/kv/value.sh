if [[ -z $2 ]] ; then
    echo "Usage: $0 <secret> <value> [additional fields]"
    exit 1
fi

secret=$1
value="$2"
shift 2

vault kv put secret/$secret "value=$value" "$@"

