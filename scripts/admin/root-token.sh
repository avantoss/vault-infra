if [[ -z $1 ]] ; then
    echo "Usage: $0 <display name>"
    exit 1
fi

vault token create -orphan -policy=root -display-name="$1" -metadata=username="$1"
