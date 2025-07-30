variable "home-directory" {}
#Docker related variables
variable "docker-network" {}

#Database Container related variables
variable "db-container-name" {}
variable "db-docker-image" {}
variable "db_root_password" {}
variable "db_volume" {}

#James Server related variables
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
    ports:
      - "3306:3306"
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
      #Port 8000 is used for the REST API of James
      - "8000:8000"

    networks:
      - ${var.docker-network}
    depends_on:
      - mariadb

  suitecrm:
    image: ${var.crm-docker-image}
    container_name: ${var.crm-container-name}
    volumes:
      - ${var.home-directory}crm_https_ssl_certificate.crt:/opt/bitnami/apache/conf/bitnami/certs/server.crt
      - ${var.home-directory}crm_https_ssl_chain_certificate.crt:/opt/bitnami/apache/conf/bitnami/certs/server-ca.crt
      - ${var.home-directory}crm_https_ssl_private_key.key:/opt/bitnami/apache/conf/bitnami/certs/server.key

      - ${var.home-directory}volumes/${var.crm_volume}:/bitnami/suitecrm
    environment:
      ALLOW_EMPTY_PASSWORD: no
      ${var.volume-initialize ? "": "#"}SUITECRM_USERNAME: ${var.crm_user_username}
      ${var.volume-initialize ? "": "#"}SUITECRM_PASSWORD: ${var.crm_user_password}
      SUITECRM_DATABASE_USER: ${var.crm-db-username}
      SUITECRM_DATABASE_PASSWORD: ${var.crm-db-password}
      SUITECRM_DATABASE_NAME: ${var.crm-db-name}
    networks:
      - ${var.docker-network}
    ports:
      # We need 8080 for the REST API of SuiteCRM and 8443 for the web interface on HTTPS.
      - "8080:8080"
      - "8443:8443"
    depends_on:
      - mariadb
      - james

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
      JOOMLA_ADMIN_USERNAME: admwinther
      JOOMLA_ADMIN_PASSWORD: admin
      JOOMLA_ADMIN_EMAIL: joomla@awin.dk
    volumes:
      - ${var.home-directory}volumes/${var.joomla_volume}:/var/www/html
      - ${var.home-directory}php.ini:/usr/local/etc/php/php.ini
      # - ${var.home-directory}configuration.php:/var/www/html/configuration.php
      # - ${var.home-directory}.htaccess:/var/www/html/.htaccess
    networks:
      - ${var.docker-network}
    depends_on:
        - mariadb
        - james


  ngx:
      image: ${var.nginx-image}
      container_name: ${var.nginx-container-name}
      volumes:
          - ${var.home-directory}nginx.conf:/etc/nginx/nginx.conf
          - ${var.home-directory}crm_https_ssl_certificate.crt:/etc/nginx/crm_ssl-certificate.crt
          - ${var.home-directory}crm_https_ssl_private_key.key:/etc/nginx/crm_ssl_certificate_key.key
          - ${var.home-directory}crm_https_ssl_chain_certificate.crt:/etc/nginx/crm_ssl_ca_certificate.crt


          - ${var.home-directory}joomla_https_ssl_fullchain.crt:/etc/nginx/joomla_https_ssl_fullchain.crt
          - ${var.home-directory}joomla_https_ssl_private_key.key:/etc/nginx/joomla_ssl_certificate_key.key
      networks:
          - ${var.docker-network}
      ports:
          #NGINX must be in control of the ports 80 and 443.
          #If traffic from other containers should be redirected to port 80 or 443, then the nginx.conf file must be edited.
          - "80:80"
          - "443:443"
      depends_on:
          - suitecrm

networks:
  ${var.docker-network}:

EOF
}