variable "my_ip_address" {}
resource "local_file" "nginx_conf" {
  filename = "nginx.conf"
  content  = <<EOF
events{}
http{
  proxy_buffer_size   128k;
  proxy_buffers   4 256k;
  proxy_busy_buffers_size   256k;
  server {
    listen 80;
    server_name crm.awin.dk;

    return 301 https://$host$request_uri; # Redirect HTTP to HTTPS
  }
  server {
      listen 443 ssl;
      server_name crm.awin.dk;

      ssl_certificate /etc/nginx/ssl-certificate.crt;
      ssl_certificate_key /etc/nginx/ssl_certificate_key.key;
      ssl_trusted_certificate /etc/nginx/ssl_ca_certificate.crt;

      location / {
          proxy_pass https://crm.awin.dk:8443; # Use the host computer's IP address
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
      }
  }
}
EOF
}
