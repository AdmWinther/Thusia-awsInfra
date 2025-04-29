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
}
EOF
}
