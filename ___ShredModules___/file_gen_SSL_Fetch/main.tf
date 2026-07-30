variable "elastic_ip" {}
variable "home-directory" {}
variable "ssh_private_key_file" {}

resource "local_file" "SSL_Fetch" {
  filename        = "SSL_Fetch.sh"
  file_permission = "0700"
  content  = replace( <<EOF
#!/bin/bash
# Run this on YOUR LOCAL MACHINE, from the infra repo root — both the SSH key and
# the destination directory are relative paths.
set -euo pipefail

echo "SSL fetch is going to transfer your files from your instance to your local machine."
echo "Just let it do its work and relax. You are in a good hand."

scp -i ${var.ssh_private_key_file} \
  ec2-user@${var.elastic_ip}:${var.home-directory}fullchain.pem \
  ec2-user@${var.elastic_ip}:${var.home-directory}privkey.pem \
  ec2-user@${var.elastic_ip}:${var.home-directory}cert.pem \
  ec2-user@${var.elastic_ip}:${var.home-directory}chain.pem \
  ec2-user@${var.elastic_ip}:${var.home-directory}keystore \
  ./SSL-certificates/

# privkey.pem and the keystore both carry the private key: owner-only.
chmod 600 ./SSL-certificates/privkey.pem ./SSL-certificates/keystore

echo "SSL certificate files are fetched into ./SSL-certificates/"

EOF
    , "\r", "")
}