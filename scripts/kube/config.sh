
exe=$0
function usage {
    echo "Usage: $exe -c <cluster> [-n <namespace>] [-a service-account] [-s suffix]"
}

cluster=""
namespace="default"
account="vault-tokenreview"
suffix=""

while getopts ":c:n:a:s:" opt; do
    case $opt in
        c) 
            cluster="$OPTARG"
            ;;
        n) 
            namespace="$OPTARG"
            ;;
        a)
            account="$OPTARG"
            ;;
        s)
            suffix="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;; 
    
        :)
            echo "Option -$OPTARG requires an argument" >&2
            ;;
    esac 
done

shift $((OPTIND-1))

if [[ -z $cluster || -z $namespace ]] ; then
    usage
    exit 1
fi

dir=$(dirname $0)

path="kube-${cluster}"
if [[ -n $suffix ]] ; then
    path="${path}-${suffix}"
fi

set -x

$dir/token-account.sh 
$dir/token-rbac.sh $namespace $account

vault auth enable -path=$path kubernetes
kcvault --debug -c ${cluster}.kube.tstllc.net config -n $namespace -a $account -p $path
