dir=$(dirname $0)
. $dir/../vault.inc

token=$(vault print token)

function tune {
    mount="$1"
    data="$2"
    echo "Updating: $mount"
    curl -sS \
        --header "X-Vault-Token: $token" \
        --request POST \
        --data "$data" \
        $VAULT_ADDR/v1/sys/mounts/$mount/tune
}

tune "secret" \
    '{ 
        "audit_non_hmac_request_keys": [ 
            "accessor",
            "client_token_accessor"
        ],
        "audit_non_hmac_response_keys": [ 
            "created_time",
            "deletion_time"
        ]
    }' 

tune "kv" \
    '{ 
        "audit_non_hmac_request_keys": [ 
        ],
        "audit_non_hmac_response_keys": [ 
        ]
    }' 


tune "database" \
    '{ 
        "audit_non_hmac_request_keys": [ 
        ],
        "audit_non_hmac_response_keys": [ 
        ]
    }' 

tune "aws" \
    '{ 
        "audit_non_hmac_request_keys": [ 
        ],
        "audit_non_hmac_response_keys": [ 
        ]
    }' 

tune "ad" \
    '{ 
        "audit_non_hmac_request_keys": [ 
        ],
        "audit_non_hmac_response_keys": [ 
        ]
    }' 
