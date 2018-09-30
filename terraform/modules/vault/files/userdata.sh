#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

# Get the Instance ID
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# Set the Hostname
hostnamectl set-hostname "${ name_prefix }-$INSTANCE_ID"
systemctl restart rsyslog.service

# Get Configuration and SSL Certs
aws --region ${ region } s3 cp s3://${ vault_resources_bucket_name }/resources/config/config.hcl /etc/vault/config.hcl

# https://www.vaultproject.io/docs/configuration/listener/tcp.html#tls_key_file
aws --region ${ region } s3 cp s3://${ vault_resources_bucket_name }/resources/ssl/cert.crt      /etc/vault/ssl/cert.crt

# https://www.vaultproject.io/docs/configuration/listener/tcp.html#tls_client_ca_file
aws --region ${ region } s3 cp s3://${ vault_resources_bucket_name }/resources/ssl/privkey.key   /etc/vault/ssl/privkey.key

# Get My IP Address
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Add My IP Address as cluster_address in Vault Configuration
sed -i -e "s/MY_IP_SET_IN_USERDATA/$MYIP/g" /etc/vault/config.hcl

# Start Vault now and on boot
systemctl enable vault
systemctl start vault
