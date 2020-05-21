if [[ -z $1 ]] ; then
    echo "Usage: $0 <nonce>"
    exit 1
fi
vault operator rekey -nonce=$1
