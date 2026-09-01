variable "domain_name" {}
variable "ssh_private_key_file" {}

resource "local_file" "connect_sh" {
  #This module generate script connect.sh, a file that can be used to SSH tunnel to the server.
  filename = "connect.sh"
  content  = <<EOF
ssh -i ${var.ssh_private_key_file} ec2-user@${var.domain_name}
EOF
}
