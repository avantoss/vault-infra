# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_security_group" "vault_sg_in_alb" {
  name        = "vault_${ var.env }_sg_in_alb"
  description = "Allow traffic into the vault alb"

  vpc_id = "${ var.vpc_id }"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${ var.alb_allowed_ingress_cidrs }"]
  }

  # Restricting egress to just the vault ec2 security group would
  # cause a dependency loop, but we can at least restrict egress
  # to only a subset of the internal network
  egress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["${ var.alb_allowed_egress_cidrs }"]
  }

  tags = "${ merge(
    map(
      "Name",
      "vault_sg_in_alb"
    ),
    var.tags ) }"
}

resource "aws_security_group" "vault_sg_in_ec2" {
  name        = "vault_${ var.env }_sg_in_ec2"
  description = "Allow traffic into the vault EC2 instances from the alb"

  vpc_id = "${ var.vpc_id }"

  ingress {
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = ["${ aws_security_group.vault_sg_in_alb.id }"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${ merge(
    map(
      "Name",
      "vault_sg_in_ec2"
    ),
    var.tags ) }"
}

resource "aws_security_group" "vault_sg_in_cluster" {
  name        = "vault_${ var.env }_sg_in_cluster"
  description = "Allow vault EC2 instances to communicate on the cluster port"

  vpc_id = "${ var.vpc_id }"

  ingress {
    from_port = 8201
    to_port   = 8201
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 8201
    to_port   = 8201
    protocol  = "tcp"
    self      = true
  }

  tags = "${ merge(
    map(
      "Name",
      "vault_sg_${ var.env }_in_cluster"
    ),
    var.tags ) }"
}
