resource "local_file" "etc_hosts" {
  #This module generate the file /etc/hosts.
  #This file defines which requests must be accepted by the server.
  filename = "hosts"
  content  = <<EOF
127.0.0.1   crm.awin.dk
127.0.0.1   localhost
::1         localhost6 localhost6.localdomain6
EOF
}
