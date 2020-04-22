if [[ -z $1 ]] ; then
    echo "Usage: $0 <lease id>"
    exit 1
fi
lease=$1

vault lease renew $lease

