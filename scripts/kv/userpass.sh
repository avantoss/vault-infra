if [[ -z $3 ]] ; then
    echo "Usage: $0 <secret> <user> <password> [additional values]"
    exit 1
fi

secret=$1
user=$2
password="$3"
shift 3

vault kv put secret/$secret user=$user "password=$password" "$@"

