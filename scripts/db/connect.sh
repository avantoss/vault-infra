if [[ -z $2 ]] ; then
    echo "Usage: $0 <database> <role>"
    exit 1
fi
database=$1
role=$2

vault read database/creds/${database}-${role}
