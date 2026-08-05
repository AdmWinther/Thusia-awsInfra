variable "home-directory" {}
#Docker related variables
variable "docker-network" {}

variable "domain_name" {}

#Database Container related variables
variable "db-container-name" {}
variable "db-docker-image" {}
variable "db_root_password" {}
variable "db_volume" {}

#James Server related variables
variable "email_server_API_url" {}
variable "email_server_API_port" {}
variable "james-container-name" {}
variable "james-docker-image" {}

#CRM related variables
variable "crm-container-name" {}
variable "crm-docker-image" {}
variable "crm-db-name" {}
variable "crm-db-username" {}
variable "crm-db-password" {}
variable "crm_volume" {}
variable "crm_user_username" {}
variable "crm_user_password" {}
variable "crm_exposed_port_of_container_for_web" {}
variable "crm_web_port_on_host" {}

#Nginx related variables
variable "nginx-image" {}
variable "nginx-container-name" {}

#Joomla related variables
variable "joomla_db_name" {}
variable "joomla_db_username" {}
variable "joomla_db_password" {}
variable "joomla-container-name" {}
variable "joomla-docker-image" {}
variable "joomla_volume" {}
variable "joomla_web_port_on_host" {}
variable "joomla_admin_password" {}
variable "joomla_admin_username" {}

#Rest API related variables
variable "rest-api-container-name" {}
variable "rest_api_docker_image" {}
variable "rest_api_port_on_host" {}
variable "CRM_API_AuthenticationClientId" {}
variable "CRM_API_AuthenticationClientSecret" {}
variable "JOOMLA_API_TOKEN" {}
variable "CRM_Mask_Email_Module_Name" {}

#Wordpress related variables
# variable "wordpress-docker-image" {}
# variable "wordpress-container-name" {}
# variable "wordpress_volume" {}
# variable "wordpress_db_name" {}
# variable "wordpress_db_username" {}
# variable "wordpress_db_password" {}

#EBC volume related variables
variable "volume-initialize" {
  type = bool
}

resource "local_file" "docker_compose_yml" {
  filename = "compose.yml"
  content  = <<EOF

name: Thusia

services:
  mariadb:
    image: ${var.db-docker-image}
    container_name: ${var.db-container-name}
    restart: always
    volumes:
      - ${var.home-directory}volumes/${var.db_volume}:/var/lib/mysql
      #this line needs to be executed just the first time. It is needed for making the users and databases.
      ${!var.volume-initialize? "#": ""}- ${var.home-directory}database_init.sql:/docker-entrypoint-initdb.d/database_init.sql
    #this part is not needed because the containers communicate through the docker network.
    #ports:
    #  - "3306:3306"
    environment:
      ALLOW_EMPTY_PASSWORD: yes
      MARIADB_ROOT_PASSWORD: ${var.db_root_password}
    networks:
      - ${var.docker-network}

  james:
    image: ${var.james-docker-image}
    container_name: ${var.james-container-name}
    restart: always
    volumes:
      - ${var.home-directory}mailetcontainer.xml:/root/conf/mailetcontainer.xml
      - ${var.home-directory}smtpserver.xml:/root/conf/smtpserver.xml
      - ${var.home-directory}imapserver.xml:/root/conf/imapserver.xml
      - type: bind
        source: ${var.home-directory}james-database.properties
        target: /root/conf/james-database.properties

      - type: bind
        source: ${var.home-directory}jdbc.jar
        target: /root/libs/jdbc.jar

      - type: bind
        source: ${var.home-directory}keystore
        target: /root/conf/keystore

    ports:
      - "25:25"
      - "110:110"
      - "143:143"
      - "465:465"
      - "587:587"
      - "993:993"
      #Port 8000 is used for the REST API of James. it only un-comments for debug.
      - "${var.email_server_API_port}:8000"

    networks:
      - ${var.docker-network}
    depends_on:
      - mariadb

  crm:
    image: ${var.crm-docker-image}
    container_name: ${var.crm-container-name}
    volumes:
      - ${var.home-directory}volumes/${var.crm_volume}:/var/www/html/
    environment:
      ALLOW_EMPTY_PASSWORD: no
      ${var.volume-initialize ? "": "#"}ADMIN_USERNAME: ${var.crm_user_username}
      ${var.volume-initialize ? "": "#"}ADMIN_PASSWORD: ${var.crm_user_password}
      DB_USERNAME: ${var.crm-db-username}
      DB_PASSWORD: ${var.crm-db-password}
      DB_PORT: 3306
      DB_HOST: ${var.db-container-name}
      DB_NAME: ${var.crm-db-name}
      SITE_URL: https://crm.${var.domain_name}
    networks:
      - ${var.docker-network}
    ports:
      # We need 8080 for the REST API of SuiteCRM and 8443 for the web interface on HTTPS.
      - "8080:8080"
      - "${var.crm_web_port_on_host}:${var.crm_exposed_port_of_container_for_web}"
    depends_on:
      - mariadb

  joomla:
    image: ${var.joomla-docker-image}
    container_name: ${var.joomla-container-name}
    ports:
      # We need 8081 for the web-API of Joomla
      - "${var.joomla_web_port_on_host}:80"
    environment:
      JOOMLA_DB_HOST: ${var.db-container-name}
      JOOMLA_DB_USER: ${var.joomla_db_username}
      JOOMLA_DB_PASSWORD: ${var.joomla_db_password}
      JOOMLA_DB_NAME: ${var.joomla_db_name}
      JOOMLA_ADMIN_USER: Joomla_Admin
      JOOMLA_ADMIN_USERNAME: ${var.joomla_admin_username}
      JOOMLA_ADMIN_PASSWORD: ${var.joomla_admin_password}
      JOOMLA_ADMIN_EMAIL: joomla@${var.domain_name}
    volumes:
      - ${var.home-directory}volumes/${var.joomla_volume}:/var/www/html
      - ${var.home-directory}php.ini:/usr/local/etc/php/php.ini
      # - ${var.home-directory}configuration.php:/var/www/html/configuration.php
      # - ${var.home-directory}.htaccess:/var/www/html/.htaccess
    networks:
      - ${var.docker-network}
    depends_on:
        - mariadb

  rest:
    image: ${var.rest_api_docker_image}
    container_name: ${var.rest-api-container-name}
    ports:
      - "${var.rest_api_port_on_host}:8080"
    environment:
      spring.profiles.active: "prod"
      TEST_ENV_VAR: "TestValue-Terraform-575458535"
      CRM_API_AuthenticationClientId: ${var.CRM_API_AuthenticationClientId}
      CRM_API_AuthenticationClientSecret: ${var.CRM_API_AuthenticationClientSecret}
      JOOMLA_API_TOKEN: ${var.JOOMLA_API_TOKEN}
      NEW_EMAIL_REQUEST_SECRET_KEY: "supersecretkey_you_store_in_env_or_config"
      CRM_API_ServerUrl : "https://crm.${var.domain_name}"
      CRM_API_AllModulesUrl: "legacy/Api/V8/module"
      CRM_NewAccountModuleName: "Accounts"
      CRM_API_AuthenticationUrl: "legacy/Api/access_token"
      JOOMLA_DOMAIN: "https://www.${var.domain_name}/"
      JOOMLA_API_BASE_URL: "api/index.php/v1"
      JOOMLA_API_USERS: "/users"
      maximumNumberOfEmailsPerUser: 3
      EMAIL_API_ServerUrl: "${var.email_server_API_url}"
      EMAIL_API_ServerPort: "${var.email_server_API_port}"
      CRM_Mask_Email_Module_Name: "${var.CRM_Mask_Email_Module_Name}"
      CRM_NewAccountTypeName: "Accounts"
    volumes:
      # We need to add the SSL certificate files to the Javas keystore as a trusted certificate. if
      # we just put the file in /tmp, then __cacert_entrypoin.sh will load it automatically to the Java keystore.
      - ${var.home-directory}fullchain.pem:/certificates/fullchain.pem
    networks:
      - ${var.docker-network}
    depends_on:
      - mariadb

  # roundcube:
  #   image: roundcube/roundcubemail:latest
  #   container_name: roundcube
  #   restart: always
  #   environment:
  #     ROUNDCUBE_DEFAULT_HOST: ${var.james-container-name}
  #     ROUNDCUBE_SMTP_SERVER: ${var.james-container-name}
  #     ROUNDCUBE_SMTP_PORT: 587
  #     ROUNDCUBE_DES_KEY: 'myrandomdeskey123' # Must be exactly 16 characters
  #   ports:
  #     - "8083:80"
  #   networks:
  #     - ${var.docker-network}
  #   depends_on:
  #     - james


  ngx:
    image: ${var.nginx-image}
    container_name: ${var.nginx-container-name}
    volumes:
      - ${var.home-directory}nginx.conf:/etc/nginx/nginx.conf

      # - ${var.home-directory}crm_https_ssl_certificate.pem:/etc/nginx/crm_https_ssl_certificate.pem
      # - ${var.home-directory}crm_https_ssl_private_key.pem:/etc/nginx/crm_https_ssl_private_key.pem
      # - ${var.home-directory}crm_https_ssl_chain_certificate.pem:/etc/nginx/crm_https_ssl_chain_certificate.pem


      # - ${var.home-directory}www_https_ssl_fullchain.pem:/etc/nginx/www_https_ssl_fullchain.pem
      # - ${var.home-directory}www_https_ssl_private_key.pem:/etc/nginx/www_ssl_certificate_key.pem

      # - ${var.home-directory}api_https_ssl_private_key.pem:/etc/nginx/api_https_ssl_private_key.pem
      # - ${var.home-directory}api_https_ssl_fullchain.pem:/etc/nginx/api_https_ssl_fullchain.pem


      - ${var.home-directory}fullchain.pem:/etc/nginx/fullchain.pem
      - ${var.home-directory}privkey.pem:/etc/nginx/privkey.pem
      - ${var.home-directory}cert.pem:/etc/nginx/cert.pem
      - ${var.home-directory}chain.pem:/etc/nginx/chain.pem

    networks:
      - ${var.docker-network}
    ports:
      #NGINX must be in control of the ports 80 and 443.
      #If traffic from other containers should be redirected to port 80 or 443, then the nginx.conf file must be edited.
      - "80:80"
      - "443:443"
    depends_on:
      - crm
      - joomla
      # - wordpress

networks:
  ${var.docker-network}:

EOF
}