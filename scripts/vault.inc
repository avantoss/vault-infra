export VAULT_ADDR=${VAULT_ADDR:-"https://vault.tstllc.net"}

export VAULT_DIRECTORY_GROUPS="devops engineers dba support"
export VAULT_SYSTEM_GROUPS="kube builder"
export VAULT_GROUPS="$VAULT_DIRECTORY_GROUPS $VAULT_SYSTEM_GROUPS"

