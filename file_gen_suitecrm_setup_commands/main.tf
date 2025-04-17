resource "local_file" "suitecrm_setup_commands" {
  filename = "commands.sh"
  content  = <<EOF
sudo docker exec -it -w /bitnami/suitecrm/ crm 'composer install'
sudo docker exec -it -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm 'openssl genrsa -out private.key 2048'
sudo docker exec -it -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm 'openssl rsa -in private.key -pubout -out public.key'
sudo docker exec -it -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm 'chmod 600 private.key public.key'
sudo docker exec -it -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm 'chown daemon:daemon p*.key'
EOF
}