if [[ -z $3 ]] ; then
    echo "Usage: $0 <secret> <access_key> <secret_key> [additional values]"
    exit 1
fi
dir=$(dirname $0)

secret="$1"
accesskey="$2"
secretkey="$3"
shift 3

$dir/put.sh "$secret" "accesskey=$accesskey" "secretkey=$secretkey" "$@"

