#!/bin/bash
#
# Test script to run inside kubernetes container.
# Copy+Paste with: cat - > token-test.sh  then Ctrl+D (EOF)
#
if [[ -z $2 ]] ; then
    echo "Usage: $0 <path> <role>"
    exit 1
fi
path=$1
role=$2
payload=/tmp/payload.json
token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo "{
  \"role\": \"reader\",
  \"jwt\": \"$token\"
}" > $payload

set -x
cat $payload
curl -v \
    --request POST \
    --data @${payload} \
    https://vault.tstllc.net/v1/auth/$path/login
