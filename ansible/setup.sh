dir=$(dirname $0)
ansible vault \
    -i $dir/inventory \
    --private-key ~/.ssh/vault-ssh-key.pem \
    -u ec2-user -m setup
