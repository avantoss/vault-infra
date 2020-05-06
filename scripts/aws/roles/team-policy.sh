if [[ -z $1 ]] ; then
    echo "Usage: $0 <team name>"
    exit 1
fi
team=$1
account="945362765384"

vault write aws/roles/team-${team} \
    policy_arns=arn:aws:iam::${account}:policy/${team}-team-policy \
    credential_type=iam_user 
