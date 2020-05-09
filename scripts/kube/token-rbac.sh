if [[ -z $2 ]] ; then
    echo "Usage: $0 <namespace> <account>"
    exit 1
fi

dir=$(dirname $0)
export NAMESPACE=$1
export NAME=$2
export ACCOUNT=$2

cat $dir/token-rbac.yml | envsubst | kubectl apply -f -
