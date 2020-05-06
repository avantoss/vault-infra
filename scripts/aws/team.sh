if [[ -z $1 ]] ; then
    echo "Usage: $0 <team>"
    exit 1
fi
dir=$(dirname $0)
team=$1

$dir/login.sh "team-${team}"

