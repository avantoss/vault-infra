if [[ -z $2 ]] ; then
    echo "Usage: $0 <role_id> <secret_id>"
    exit
fi

role=$1
secret=$2

vault write auth/approle/login \
    role_id=$role \
    secret_id=$secret
