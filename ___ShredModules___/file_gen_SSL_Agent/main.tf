variable "package-installer" {}
variable "domain_name" {}
resource "local_file" "SSL_Agent" {
  filename = "SSL_Agent.sh"
  content  = replace( <<EOF
echo "SSL agent is awake and up to the task now. Lean back and let me help you."
${var.package-installer} install certbot -y

echo "Certbot installation is done. Now requesting certificates."
certbot certonly --standalone --agree-tos --noninteractive -d ${var.domain_name} -d www.${var.domain_name} -d api.${var.domain_name} -d crm.${var.domain_name} -m admin@${var.domain_name}
#certbot certonly --standalone --agree-tos --noninteractive -d ddd.${var.domain_name} -d eee.${var.domain_name} -m admin@${var.domain_name}

cp -rL /etc/letsencrypt/live/${var.domain_name}/fullchain.pem /home/ec2-user/fullchain.pem
cp -rL /etc/letsencrypt/live/${var.domain_name}/privkey.pem /home/ec2-user/privkey.pem

echo "SSL certificate files are copied "

EOF
    , "\r", "")
}