exe=$0
function usage {
    echo "Usage: $exe -c <cluster> -n <namespace> -r <role> -p <policies> [-a service-account] [-s suffix] [-t ttl]"
}

cluster=""
namespace=""
account="default"
suffix=""
policies=""
role=""
ttl="1h"

while getopts ":c:n:a:s:p:r:t:" opt; do
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
        r)
            role="$OPTARG"
            ;;
        p)
            policies="$OPTARG"
            ;;
        t)
            ttl="$OPTARG"
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

if [[ -z $cluster || -z $namespace || -z $role || -z $policies ]] ; then
    usage
    exit 1
fi

path="kube-${cluster}-${namespace}"
if [[ -n $suffix ]] ; then
    path="${path}-${suffix}"
fi

set -x
vault write auth/$path/role/$role \
    bound_service_account_names=$account \
    bound_service_account_namespaces=$namespace \
    policies=$policies \
    ttl=$ttl
