dir=$(dirname $0)
. $dir/vault.inc

function usage {
    echo "Usage: $exe [-l | -d]"
}

list=""
details=""

while getopts ":ld" opt; do
    case $opt in
        d) 
            details="true"
            ;;
        l) 
            list="true"
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

function accessor_details {
    while read accessor ; do
        echo "----------------------------------------------------------------------"
        echo $accessor
        echo "----------------------------------------------------------------------"
        curl -s \
            --header "X-Vault-Token: $(vault print token)" \
            --request POST \
            --data "{ \"accessor\": \"$accessor\" }" \
            $VAULT_ADDR/v1/auth/token/lookup-accessor | jq .
    done
}

if [[ -n $list ]] ; then
    curl -s \
        --header "X-Vault-Token: $(vault print token)" \
        --request LIST \
        $VAULT_ADDR/v1/auth/token/accessors | jq .
elif [[ -n $details ]] ; then
    curl -s \
        --header "X-Vault-Token: $(vault print token)" \
        --request LIST \
        $VAULT_ADDR/v1/auth/token/accessors | jq -r '.data.keys[]' | accessor_details
else
    usage
    exit 1
fi
