if [[ -z $2 ]] ; then
    echo "Usage: $0 <otp> <encoded token>"
    exit 1
fi
vault operator generate-root \
   -decode="$2" \
   -otp="$1"
