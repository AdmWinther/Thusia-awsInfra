variable "home-directory" {}
variable "domain_name" {}
#Docker related variables
variable "docker-network" {}

#Database Container related variables
variable "db-container-name" {}
variable "db-docker-image" {}
variable "db_software" {}
variable "db_root_password" {}
variable "db_driver_className" {}
variable "db_volume" {}

#James Server related variables
variable "james_db_name" {}
variable "james_db_username" {}
variable "james_db_password" {}
variable "james-container-name" {}
variable "james-docker-image" {}
variable "james_s3_bucket_name" {}

#Test and demo emails password
variable "awin_password" {}
variable "jpo_password" {}
variable "fbl_password" {}
variable "dmarc_reports_password" {}

variable "john_password" {}
variable "jane_password" {}
variable "test_password" {}
variable "demo_password" {}

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

#Rest-API related variables
variable "rest_api_db_name" {}
variable "rest_api_db_username" {}
variable "rest_api_db_password" {}

#EBC volume related variables
variable "volume-initialize" {
  type = bool
}

module "file_gen_james_database_properties" {
  source = "../file_gen_james_database_properties"
  db_software           = var.db_software
  db-container-name     = var.db-container-name
  james_db_username           = var.james_db_username
  james_db_password           = var.james_db_password
  db_driver_className   = var.db_driver_className

  james_db_name         = var.james_db_name
}


module "file_gen_database_init" {
  source = "../file_gen_database_init"
  james_db_name = var.james_db_name
  james_db_username = var.james_db_username
  james_db_password = var.james_db_password

  crm_db_name   = var.crm-db-name
  crm_db_username   = var.crm-db-username
  crm_db_password   = var.crm-db-password


  rest_api_db_name   = var.rest_api_db_name
  rest_api_db_username   = var.rest_api_db_username
  rest_api_db_password   = var.rest_api_db_password
}

module "file_gen_nginx_conf" {
  source = "../file_gen_nginx_conf"
}

module "file_gen_crm_initialize_sh" {
  source = "../file_gen_crm_initialize_sh"
}

module "file_gen_james_initialize_sh" {
  source = "../file_gen_james_initialize_sh"
    awin_password           = var.awin_password
    jpo_password            = var.jpo_password
    fbl_password            = var.fbl_password
    dmarc_reports_password  = var.dmarc_reports_password

    john_password           = var.john_password
    jane_password           = var.jane_password
    test_password           = var.test_password
    demo_password           = var.demo_password
}

module "file_gen_pg_hba_conf" {
  source = "../file_gen_pg_hba_conf"
}

module "file_gen_etc_hosts" {
  source = "../file_gen_etc_hosts"
}

module "file_gen_imapserver_xml" {
  source = "../file_gen_imapserver_xml"
}

module "file_gen_smtpserver_xml" {
  source = "../file_gen_smtpserver_xml"
}

module "file_gen_mailetcontainer_xml" {
  source = "../file_gen_james_mailetcontainer_xml"
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
      - ${var.home-directory}smtpserver.xml:/root/conf/smtpserver.xml
      - ${var.home-directory}imapserver.xml:/root/conf/imapserver.xml
      - type: bind
        source: ${var.home-directory}james-database.properties
        target: /root/conf/james-database.properties

      - type: bind
        source: ${var.home-directory}jdbc.jar
        target: /root/libs/jdbc.jar

      - type: bind
        source: ${var.home-directory}keystore_ca
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
      - "8080:8080"
      - "8443:8443"
    depends_on:
      - mariadb
      - james

  ngx:
    image: ${var.nginx-image}
    container_name: ${var.nginx-container-name}
    volumes:
      - ${var.home-directory}nginx.conf:/etc/nginx/nginx.conf
    network_mode: host
    depends_on:
      - suitecrm

networks:
  ${var.docker-network}:

EOF
}