# The MIT License (MIT)
#
# Copyright (c) 2014-2018 Avant, Sean Lingren

resource "aws_launch_configuration" "lc" {
  name_prefix          = "vault_"
  image_id             = "${ var.ami_id }"
  instance_type        = "${ var.instance_type }"
  key_name             = "${ var.ssh_key_name }"
  iam_instance_profile = "${ aws_iam_instance_profile.vault_ec2_instance_profile.id }"
  user_data            = "${ data.template_file.userdata.rendered }"

  ebs_optimized               = false
  enable_monitoring           = false
  associate_public_ip_address = false

  security_groups = ["${ aws_security_group.vault_sg_in_ec2.id }"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
