if [[ -z $2 ]] ; then
    echo "Usage: $0 <secret> <value> [additional fields]"
    exit 1
fi

secret=$1
value="$2"
shift 2

dir=$(dirname $0)
$dir/secret.sh $secret "value=$value" "$@"

