if [[ -z $2 ]] ; then
    echo "Usage: $0 <bucket> <role>"
    exit 1
fi
dir=$(dirname $0)
bucket=$1
role=$2

$dir/login.sh "bucket-${bucket}-${role}"

