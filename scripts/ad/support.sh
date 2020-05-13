vault write ad/library/support-team \
    service_account_names=supportuser@active-directory.infra.tstllc.net \
    ttl=10h \
    max_ttl=20h \
    disable_check_in_enforcement=false
