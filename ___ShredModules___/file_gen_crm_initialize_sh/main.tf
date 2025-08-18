resource "local_file" "crm_initialize_sh" {
  filename = "crm_initialize.sh"
  content  = replace( <<EOF
docker exec -w /bitnami/suitecrm/ crm bash -c 'composer install'
docker exec -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm bash -c 'openssl genrsa -out private.key 2048'
docker exec -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm bash -c 'openssl rsa -in private.key -pubout -out public.key'
docker exec -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm bash -c 'chmod 600 private.key public.key'
docker exec -w /bitnami/suitecrm/public/legacy/Api/V8/OAuth2/ crm bash -c 'chown daemon:daemon p*.key'
EOF
    , "\r", "")
}