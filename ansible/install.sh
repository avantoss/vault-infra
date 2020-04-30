dir=$(dirname $0)
ansible-playbook \
    -i $dir/inventory \
    --private-key ~/.ssh/vault-ssh-key.pem \
    --vault-password-file $dir/../../terraform/.secrets/ansible-vault.pwd \
    $dir/playbook.yml
