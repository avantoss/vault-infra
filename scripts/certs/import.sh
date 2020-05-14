dir=$(dirname $0)
root=$dir/../../..
certs=$root/kube-deploy/.certs

function import_cert {
    cert=$1
    base=${cert%%.cert}
    name=${base##*/}
    key="${base}.key"
    cfg="${base}.cfg"
    echo "${name}"

    if [[ -f $key ]] ; then
        opts=""
        if [[ -f $cfg ]] ; then
           echo "<  Has config: ${name}  >"
           opts="$opts config=@${cfg}"
        fi
        vault kv put secret/provisioning/certs/$name cert=@${cert} key=@${key} $opts
    else
        echo "No key for: ${name}"
    fi
}

if [[ -z $1 ]] ; then
    for cert in $(ls $certs/*.cert) ; do
        import_cert $cert
    done
else
    for cert in "$@" ; do
        import_cert $cert
    done
fi
