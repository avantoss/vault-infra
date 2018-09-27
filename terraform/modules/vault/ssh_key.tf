# SSH Key
resource "aws_key_pair" "vault_ec2_ssh_key" {
  key_name   = "${ var.ssh_key_name }"
  public_key = "${ var.ssh_public_key }"
}
