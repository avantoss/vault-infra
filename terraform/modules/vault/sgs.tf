# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

############################
## ALB #####################
############################
resource "aws_security_group" "vault_sg_in_alb" {
  name        = "${ var.name_prefix }_sg_in_alb"
  description = "Allow traffic into the vault alb"

  vpc_id = "${ var.vpc_id }"

  tags = "${ merge(
    map("Name", "${ var.name_prefix }_sg_in_alb"),
    var.tags ) }"
}

resource "aws_security_group_rule" "vault_sg_in_alb_80" {
  type              = "ingress"
  security_group_id = "${ aws_security_group.vault_sg_in_alb.id }"

  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["${ var.alb_allowed_ingress_cidrs }"]
}

resource "aws_security_group_rule" "vault_sg_in_alb_443" {
  type              = "ingress"
  security_group_id = "${ aws_security_group.vault_sg_in_alb.id }"

  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["${ var.alb_allowed_ingress_cidrs }"]
}

resource "aws_security_group_rule" "vault_sg_out_alb_8200" {
  type              = "egress"
  security_group_id = "${ aws_security_group.vault_sg_in_alb.id }"

  protocol                 = "tcp"
  from_port                = 8200
  to_port                  = 8200
  source_security_group_id = "${ aws_security_group.vault_sg_in_ec2.id }"
}

############################
## EC2 #####################
############################
resource "aws_security_group" "vault_sg_in_ec2" {
  name        = "${ var.name_prefix }_sg_in_ec2"
  description = "Allow traffic into the vault EC2 instances from the alb"

  vpc_id = "${ var.vpc_id }"

  tags = "${ merge(
    map("Name", "${ var.name_prefix }_sg_in_ec2"),
    var.tags ) }"
}

resource "aws_security_group_rule" "vault_sg_in_ec2_8200" {
  type              = "ingress"
  security_group_id = "${ aws_security_group.vault_sg_in_ec2.id }"

  protocol                 = "tcp"
  from_port                = 8200
  to_port                  = 8200
  source_security_group_id = "${ aws_security_group.vault_sg_in_alb.id }"
}

resource "aws_security_group_rule" "vault_sg_in_ec2_8201" {
  type              = "ingress"
  security_group_id = "${ aws_security_group.vault_sg_in_ec2.id }"

  protocol  = "tcp"
  from_port = 8201
  to_port   = 8201
  self      = true
}

resource "aws_security_group_rule" "vault_sg_out_ec2_all" {
  type              = "ingress"
  security_group_id = "${ aws_security_group.vault_sg_in_ec2.id }"

  protocol         = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
