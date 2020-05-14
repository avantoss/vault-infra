if [[ -z $3 ]] ; then
    echo "Usage: $0 <secret> <user> <password> [additional values]"
    exit 1
fi

secret=$1
user=$2
password="$3"
shift 3

dir=$(dirname $0)
$dir/secret.sh $secret user=$user "password=$password" "$@"
