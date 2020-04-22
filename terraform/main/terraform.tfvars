# The MIT License (MIT)
# Copyright (c) 2014-2020 Avant, Sean Lingren

############################
## Environment #############
############################
name_prefix    = "vault-prod"
region         = "us-east-1"
dr_region      = "us-east-2"

# Tags and tags_asg must be duplicated to handle the
# map expected for most terraform tag blocks and list
# of maps expected when tagging instances in an ASG
tags = {
  env        = "prod"
  department = "devops"
  syscontact = "david.cox"
}

############################
## Route53 #################
############################
# Route53 support is under a switch `route53_enabled`
route53_enabled     = true
zone_id             = "ZEQQF576RZ5PS" # Route53 zone id

############################
## Networking ##############
############################
vault_dns_address = "https://vault.tstllc.net:443"

vpc_id = "vpc-69eb300e"

alb_subnets = ["subnet-0b4bba6fdae731322", "subnet-2dd60071", "subnet-0fff54875920968e1" ] 
ec2_subnets = ["subnet-0b4bba6fdae731322", "subnet-2dd60071", "subnet-0fff54875920968e1" ] 

alb_allowed_ingress_cidrs = [
  # office
  "192.168.0.0/16", 
  "100.64.0.0/10",
  "34.228.89.19/32",
  # aws
  "172.30.0.0/16",
  "172.31.0.0/16",
  # internal
  "100.96.0.0/11",
  "10.2.0.0/16",
  # builds
  "18.207.65.120/32"
]

############################
## ALB #####################
############################
alb_certificate_arn = "arn:aws:acm:us-east-1:945362765384:certificate/2c8bfc92-8e84-415d-b933-9a108e7f5f40"

############################
## EC2 #####################
############################
ami_id        = "ami-00ba1ee6d5c1913fa"
instance_type = "r4.large"
ssh_key_name  = "vault-ssh-key"

asg_min_size         = 2
asg_max_size         = 3
asg_desired_capacity = 2

############################
## S3 ######################
############################
vault_resources_bucket_name = "tstllc-vault-resources"
vault_data_bucket_name      = "tstllc-vault-data"

############################
## DynamoDB ################
############################
dynamodb_table_name = "tstllc-vault-ha-coordination"

vault_additional_config = <<EOF

log_level = "trace"

EOF
