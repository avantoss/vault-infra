#!/bin/bash
#
# Test script to run inside kubernetes container.
# Copy+Paste with: cat - > token-test.sh  then Ctrl+D (EOF)
#
if [[ -z $2 ]] ; then
    echo "Usage: $0 <path> <role> [token]"
    exit 1
fi
path=$1
role=$2
payload=/tmp/payload.json
if [[ -n $3 ]] ; then
    token=$3
else 
    token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
fi

echo "{
  \"role\": \"$role\",
  \"jwt\": \"$token\"
}" > $payload

set -x
cat $payload
curl \
    --request POST \
    --data @${payload} \
    https://vault.tstllc.net/v1/auth/$path/login
