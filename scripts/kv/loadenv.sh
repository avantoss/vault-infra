if [[ -z $1 ]] ; then
    echo "Usage: $0 <environment>"
    exit 1
fi

dir=$(dirname $0)
# secrets=$dir/../../../kube-deploy/.secrets
secrets=/tmp

function value {
    key=$1
    grep "^${key}=" $secrets/${env}.env | cut -d= -f 2 | sed 's/^@/\\@/'
}

env=$1

$dir/userpass.sh kube/$env/db $(value DB_USER) $(value DB_PASSWORD)
$dir/awskey.sh kube/$env/aws $(value RANCHER_ACCESS_KEY) $(value RANCHER_SECRET_KEY)
$dir/value.sh kube/${env}/launchdarkly $(value LAUNCHDARKLY_KEY)
$dir/value.sh kube/${env}/slack $(value SLACK_KEY)

$dir/put.sh kube/$env/secret \
    crypto=$(value CRYPTO_SECRET) \
    client=$(value CLIENT_SECRET)

$dir/put.sh kube/$env/atpco \
    user=$(value ATPCO_USER) \
    password=$(value ATPCO_PASSWORD)  \
    pseudocity=$(value ATPCO_PSEUDOCITY) \
    agt=$(value ATPCO_AGT) \
    agtpwd=$(value ATPCO_AGTPWD) \
    agtrole=$(value ATPCO_AGTROLE) \
    agy=$(value ATPCO_AGY)

$dir/value.sh kube/${env}/viator $(value ACTIVITY_VIATOR_API_KEY)

$dir/put.sh kube/${env}/ace \
    user=$(value ACE_WEBSERVICES_USERNAME) \
    password=$(value ACE_WEBSERVICES_PASSWORD)  \
    secret=$(value ACE_VENDOR_AUTH_SECRET)

$dir/put.sh kube/${env}/connexions \
    user=$(value CONNEXIONS_AUTH_USER_NAME)  \
    key=$(value CONNEXIONS_AUTH_SHARED_KEY)

# gws_url=$(value GWS_URL)
# if [[ -n $gws_url ]] ; then
    $dir/userpass.sh kube/${env}/gws \
        "$(value GWS_USERNAME)"  \
        "$(value GWS_PASSWORD)"
# fi
