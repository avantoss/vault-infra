if [[ -z $1 ]] ; then
    echo "Usage: $0 <bucket>"
    exit 1
fi

dir=$(dirname $0)
export bucket=$1

if ! which envsubst > /dev/null ; then
    echo "GNU gettext is required, installing ..."
    brew install gettext
    brew link --force gettext
fi

cat $dir/bucket-write.tmpl | envsubst > /tmp/bucket-write.policy
cat $dir/bucket-readonly.tmpl | envsubst > /tmp/bucket-readonly.policy

vault write aws/roles/bucket-${bucket}-write \
    credential_type=iam_user \
    policy_document=@/tmp/bucket-write.policy

vault write aws/roles/bucket-${bucket}-readonly \
    credential_type=iam_user \
    policy_document=@/tmp/bucket-readonly.policy



