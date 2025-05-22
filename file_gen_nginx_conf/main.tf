resource "local_file" "nginx_conf" {
  filename = "nginx.conf"
  content  = <<EOF
events{}
http{
  server {
    listen 80;
    server_name crm.awin.dk;

    location / {
        proxy_pass http://awin.dk:8080; # Use the host computer's IP address
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
  server {
      listen 443 ssl;
      server_name crm.awin.dk;

      #ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
      #ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

      location / {
          #proxy_pass http://awin.dk:8080; # Use the host computer's IP address
          proxy_pass http://awin.dk:8443; # Use the host computer's IP address
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
      }
  }
}
EOF
}
