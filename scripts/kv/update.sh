#!/bin/bash

if [[ -z $2 ]] ; then
    echo "Usage: $0 <path> <key=value>..."
    exit 1
fi
path="$1"
shift

set -x
dir=$(dirname $0)
current=$($dir/pairs.sh -p "$path" -s)
if [[ -n $current ]] ; then
    $dir/put.sh "$path" $current "$@"
fi
