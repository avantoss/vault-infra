# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_launch_template" "lt" {
  name_prefix = "${ var.name_prefix }-"

  image_id      = "${ var.ami_id }"
  instance_type = "${ var.instance_type }"
  key_name      = "${ var.ssh_key_name }"
  user_data     = "${ base64encode( data.template_file.userdata.rendered ) }"

  iam_instance_profile {
    name = "${ aws_iam_instance_profile.vault_ec2_instance_profile.id }"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = "100"
    }
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = ["${ aws_security_group.ec2.id }"]
  }

  tag_specifications {
    resource_type = "instance"

    tags = "${ merge(
      map( "Name", "${ var.name_prefix }" ),
      var.tags ) }"
  }

  tag_specifications {
    resource_type = "volume"

    tags = "${ merge(
      map( "Name", "${ var.name_prefix }" ),
      var.tags ) }"
  }

  tags = "${ merge(
    map( "Name", "${ var.name_prefix }" ),
    var.tags ) }"
}

resource "aws_autoscaling_group" "asg" {
  name_prefix = "${ var.name_prefix }-"

  launch_template {
    id      = "${ aws_launch_template.lt.id }"
    version = "$$Latest"
  }

  vpc_zone_identifier = ["${ var.ec2_subnets }"]
  target_group_arns   = ["${ aws_lb_target_group.tg.arn }"]

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

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tags = [
    "${ map( "key", "Name", "value", var.name_prefix, "propagate_at_launch", "true" ) }",
    "${ data.null_data_source.asg_tags.*.outputs }",
  ]
}
