# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_autoscaling_group" "asg" {
  name = "vault_asg_${ var.env }"

  launch_configuration = "${ aws_launch_configuration.lc.name }"
  vpc_zone_identifier  = ["${ var.ec2_subnets }"]
  target_group_arns    = ["${ aws_alb_target_group.tg.arn }"]

  min_size         = "${ var.asg_min_size }"
  max_size         = "${ var.asg_max_size }"
  desired_capacity = "${ var.asg_desired_capacity }"

  # Don't use ELB as the health check because we do not want
  # AWS to start cycling instances when Vault is unhealthy,
  # since our health check will only have one healthy at a time
  health_check_type = "EC2"

  health_check_grace_period = 300
  wait_for_capacity_timeout = 0
  termination_policies      = ["OldestInstance"]

  tags = [{
    key                 = "Name"
    value               = "vault"
    propagate_at_launch = true
  }]

  tags = [
    "${ var.tags_asg }",
  ]
}
