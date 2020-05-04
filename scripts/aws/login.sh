if [[ -z $1 ]] ; then
    echo "Usage: $0 <role>"
    exit 1
fi

role=$1

vault read aws/creds/$1

