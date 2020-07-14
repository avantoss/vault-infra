export VAULT_ADDR=${VAULT_ADDR:-"https://vault.tstllc.net"}

export VAULT_DIRECTORY_GROUPS="devops secops provisioning engineers dba support hotel"
export VAULT_SYSTEM_GROUPS="kube builder certificates"
export VAULT_GROUPS="$VAULT_DIRECTORY_GROUPS $VAULT_SYSTEM_GROUPS"

function vault_leader {
    curl -s \
        --header "X-Vault-Token: $(vault print token)" \
        --request GET \
        $VAULT_ADDR/v1/sys/leader | jq -r .leader_cluster_address | sed -nE 's/.*\/\/(.*):.*/\1/p'
}
