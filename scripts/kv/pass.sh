if [[ -z $2 ]] ; then
    echo "Usage: $0 <secret> <password> [additional values]"
    exit 1
fi

secret=$1
password="$2"
shift 2

dir=$(dirname $0)
$dir/put.sh $secret "password=$password" "$@"

