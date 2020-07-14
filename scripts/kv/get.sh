if [[ -z $1 ]] ; then
    echo "Usage: $0 <secret>"
    exit 1
fi

secret="$1"
shift

vault kv get "$@" "secret/$secret"

