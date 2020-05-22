
function usage {
    echo "Usage: $exe -p <path> [-s (short) ] [-q (quotes)]"
}

path=""
short=""
quotes=""

while getopts ":p:sq" opt; do
    case $opt in
        p) 
            path="$OPTARG"
            ;;
        s) 
            short="true"
            ;;
        q) 
            quotes="true"
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

if [[ -z $path ]] ; then
    usage 
    exit 1
fi


if [[ -n $quotes ]] ; then
    base=".data.data | to_entries|map(\"'\(.key)=\(.value|tostring)'\")"
else
    base='.data.data | to_entries|map("\(.key)=\(.value|tostring)")'
fi

if [[ -n $short ]] ; then
    query="$base| join(\" \")"
else
    query="$base|.[]"
fi

dir=$(dirname $0)
. $dir/../vault.inc

curl -s \
    --header "X-Vault-Token: $(vault print token)" \
    --request GET \
    "$VAULT_ADDR/v1/secret/data/$path" | jq -r "$query"
