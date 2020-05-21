if [[ -z $1 ]] ; then
    echo "Usage: $0 <otp>"
    exit 1
fi
vault operator generate-root -init -otp=$1
