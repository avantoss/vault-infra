if [[ -z $1 ]] ; then
    echo "Usage: $0 <vault ip>"
    exit 1
fi

curl -sk https://${1}:8200/v1/sys/health | jq .
