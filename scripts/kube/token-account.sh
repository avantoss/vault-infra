if [[ -z $2 ]] ; then
    echo "Usage: $0 <namespace> <account>"
    exit 1
fi
namespace=$1
account=$2

kubectl -n $namespace create serviceaccount $account
