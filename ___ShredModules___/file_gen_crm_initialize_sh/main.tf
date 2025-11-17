variable "suitecrm_image_home_directory" {}

resource "local_file" "crm_initialize_sh" {
  filename = "crm_initialize.sh"
  content  = replace( <<EOF
docker exec crm bash -c 'chown -R www-data:www-data /var/www/html'
docker exec crm bash -c 'chmod -R 755 /var/www/html'
docker exec crm bash -c 'chmod -R 775 /var/www/html/public/legacy/cache'
docker exec crm bash -c 'chmod -R 775 /var/www/html/public/legacy/custom'
docker exec crm bash -c 'chmod -R 775 /var/www/html/public/legacy/modules'
docker exec crm bash -c 'chmod -R 775 /var/www/html/public/legacy/upload'


docker exec -w ${var.suitecrm_image_home_directory}public/legacy/ crm bash -c 'composer install'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'openssl genrsa -out private.key 2048'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'openssl rsa -in private.key -pubout -out public.key'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'chown www-data:www-data private.key'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'chown www-data:www-data public.key'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'chmod 600 public.key'
docker exec -w ${var.suitecrm_image_home_directory}public/legacy/Api/V8/OAuth2/ crm bash -c 'chmod 600 public.key'
EOF
    , "\r", "")
}