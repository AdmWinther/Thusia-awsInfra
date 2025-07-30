variable "my_ip_address" {}
variable "domain_name" {}
variable "crm_web_port_On_host" {}
variable "joomla-container-name" {}
variable "joomla_web_port_On_host" {}

resource "local_file" "nginx_conf" {
  filename = "nginx.conf"
  content  = <<EOF
events{}
http{
  proxy_buffer_size   128k;
  proxy_buffers   4 256k;
  proxy_busy_buffers_size   256k;


  # Redirect HTTP to HTTPS
  server {
    listen 80;
    server_name crm.${var.domain_name};

    return 301 https://$host$request_uri; # Redirect HTTP to HTTPS
  }


  # CRM server configuration
  #Refirect HTTPS://crm.awin.dk to https://crm.awin.dk:8443
  server {
      listen 443 ssl;
      server_name crm.${var.domain_name};

      ssl_certificate /etc/nginx/crm_ssl-certificate.crt;
      ssl_certificate_key /etc/nginx/crm_ssl_certificate_key.key;
      ssl_trusted_certificate /etc/nginx/crm_ssl_ca_certificate.crt;

      location / {
          proxy_pass https://crm.${var.domain_name}:${var.crm_web_port_On_host}; # Use the host computer's IP address
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
      }
  }


  # Joomla server configuration
  #To redirect http://awin.dk to https://www.awin.dk.
  server {
      listen 80;
      server_name ${var.domain_name};

      return 301 https://www.$host$request_uri; # Redirect HTTP to HTTPS
  }

  #To redirect https://awin.dk to https://www.awin.dk.
  server {
      listen 443;
      server_name ${var.domain_name};

      return 301 https://www.$host$request_uri; # Redirect HTTP to HTTPS
  }

  #To redirect http://www.awin.dk to https://www.awin.dk.
  server {
      listen 80;
      server_name www.${var.domain_name};

      return 301 https://$host$request_uri; # Redirect HTTP to HTTPS
  }

  #To redirect https://www.awin.dk to localhost:8081.
  server {
      listen 443;
      server_name www.${var.domain_name};

      ssl_certificate /etc/nginx/joomla_https_ssl_fullchain.crt;
      ssl_certificate_key /etc/nginx/joomla_ssl_certificate_key.key;


      # The following line allow the uploading of large files in Joomla.
      client_max_body_size 100M;

      location / {
          proxy_pass http://${var.joomla-container-name}:80; # Use the Joomla container name and port
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
      }
  }
}
EOF
}
