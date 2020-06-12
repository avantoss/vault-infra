dir=$(dirname $0)
. $dir/../vault.inc

leader=$(vault_leader)

echo "Connecting to leader: $leader"
ssh -i ~/.ssh/vault-ssh-key.pem ec2-user@$leader
