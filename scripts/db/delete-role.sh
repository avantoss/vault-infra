dir=$(dirname $0)

if [[ -z $2 ]] ; then
    echo "Usage: $0 <database> <role>" 
    exit 1
fi

database=$1
role=$2

set -x
vault delete database/roles/$role 
