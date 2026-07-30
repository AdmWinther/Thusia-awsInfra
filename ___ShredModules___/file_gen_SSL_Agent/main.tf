variable "package-installer" {}
variable "james_keystore_password" {}
variable "domain_name" {}
variable "home-directory" {}

variable "certificate_subdomains" {
  description = "Subdomain labels to include in the certificate alongside the apex. Every one must already resolve to this server — certbot validates each over HTTP-01 and one unresolvable name fails the whole request."
  type        = list(string)
}

locals {
  # The apex plus one -d flag per subdomain label.
  certbot_domain_flags = join(" ", concat(
    ["-d ${var.domain_name}"],
    [for s in var.certificate_subdomains : "-d ${s}.${var.domain_name}"],
  ))
}

resource "local_file" "SSL_Agent" {
  filename = "SSL_Agent.sh"
  # This script embeds the keystore password, so keep it owner-only.
  file_permission = "0700"
  content  = replace( <<EOF
#!/bin/bash
# Run ON THE SERVER with sudo, while nothing is holding port 80 — certbot
# --standalone binds it itself, so the container stack must be down
# (bootstrap_run = true keeps it down).
set -euo pipefail

echo "SSL agent is awake and up to the task now. Lean back and let me help you."
${var.package-installer} install certbot -y

echo "Certbot installation is done. Now requesting certificates."
# --keep-until-expiring makes a re-run a no-op instead of a hard failure under
# set -e, and avoids spending a Let's Encrypt issuance (limit: 5 per week).
certbot certonly --standalone --agree-tos --noninteractive --keep-until-expiring ${local.certbot_domain_flags} -m admin@${var.domain_name}

LIVE=/etc/letsencrypt/live/${var.domain_name}

# -L dereferences the symlinks that point into ../../archive/.
for f in fullchain privkey cert chain; do
  cp -L "$LIVE/$f.pem" "${var.home-directory}$f.pem"
  chown ec2-user:ec2-user "${var.home-directory}$f.pem"
done

echo "Building the James PKCS12 keystore from the issued certificate."
openssl pkcs12 -export -in "$LIVE/fullchain.pem" -inkey "$LIVE/privkey.pem" -name james -out "${var.home-directory}keystore" -passout pass:${var.james_keystore_password}
chown ec2-user:ec2-user ${var.home-directory}keystore

# privkey.pem and the keystore both carry the private key: owner-only.
chmod 600 ${var.home-directory}privkey.pem ${var.home-directory}keystore
chmod 644 ${var.home-directory}fullchain.pem ${var.home-directory}cert.pem ${var.home-directory}chain.pem

echo "SSL certificate files are copied and the keystore is built."

EOF
    , "\r", "")
}