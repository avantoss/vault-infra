if [[ -z $2 ]] ; then
    echo "Usage: $0 <access key> <secret key>"
    exit 1
fi
access_key="$1"
secret_key="$2"

vault write aws/config/root \
    access_key=$access_key \
    secret_key=$secret_key \
    region=us-east-1
