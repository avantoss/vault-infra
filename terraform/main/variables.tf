# The MIT License (MIT)
# Copyright (c) 2014-2020 Avant, Sean Lingren

############################
## Environment #############
############################
variable "name_prefix" {
  type        = string
  description = "A name to prefix every created resource with"
}

variable "region" {
  type        = string
  description = "The AWS region to use"
}

variable "dr_region" {
  type        = string
  description = "The AWS Region to use for disaster recovery"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
}

############################
## Networking ##############
############################
variable "vault_dns_address" {
  type        = string
  description = "The DNS address that vault will be accessible at"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to use"
}

variable "alb_subnets" {
  type        = list(string)
  description = "A list of subnets to launch the ALB in"
}

variable "ec2_subnets" {
  type        = list(string)
  description = "A list of subnets to launch the EC2 instances in"
}

variable "alb_allowed_ingress_cidrs" {
  type        = list(string)
  description = "A list of CIDRs to allow traffic into the ALB"
}

############################
## ALB #####################
############################
variable "alb_certificate_arn" {
  type        = string
  description = "The ARN of the certificate to use on the ALB"
  default     = ""
}

############################
## EC2 #####################
############################
# You can replace this variable with aws_ami data provider in terraform,
# which should search for the latest AMI that you built with packer
# https://www.terraform.io/docs/providers/aws/d/ami.html
variable "ami_id" {
  type        = string
  description = "The ID of the AMI to launch. Should have been built with packer."
}

variable "instance_type" {
  type        = string
  description = "The type of instance to launch vault on"
}

variable "ssh_key_name" {
  type        = string
  description = "The name of the ssh key to use for the EC2 instance"
}

variable "asg_min_size" {
  type        = string
  description = "Minimum number of instances in the ASG"
}

variable "asg_max_size" {
  type        = string
  description = "Maximum number of instances in the ASG"
}

variable "asg_desired_capacity" {
  type        = string
  description = "Desired number of instances in the ASG"
}

############################
## S3 ######################
############################
variable "vault_resources_bucket_name" {
  type        = string
  description = "The name of the vault resources bucket"
}

variable "vault_data_bucket_name" {
  type        = string
  description = "The name of the vault data bucket"
}

############################
## DynamoDB ################
############################
variable "dynamodb_table_name" {
  type        = string
  description = "The name of the dynamodb table that vault will create to coordinate HA"
}

############################
## Route53 #################
############################
variable "route53_enabled" {
  type        = string
  description = "Whether enable Route53 resources or not"
}

variable "zone_id" {
  type        = string
  description = "ID of the Route 53 zone"
}

############################
## Config ##################
############################
variable "vault_additional_config" {
  type        = string
  description = "Additional content to include in the vault configuration file"
  default     = ""
}


