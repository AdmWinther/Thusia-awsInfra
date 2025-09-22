variable "domain_name" {}

resource "local_file" "etc_hosts" {
  #This module generate the file /etc/hosts.
  #This file defines which requests must be accepted by the server.
  # This is a server file and not a docker file or a configuration file for any of the containers.
  filename = "hosts"
  content  = <<EOF
127.0.0.1   crm.${var.domain_name}
127.0.0.1   www.${var.domain_name}
127.0.0.1   api.${var.domain_name}
127.0.0.1   ${var.domain_name}
127.0.0.1   localhost
::1         localhost6 localhost6.localdomain6
EOF
}
