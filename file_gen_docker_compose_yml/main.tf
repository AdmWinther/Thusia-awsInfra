variable "home-directory" {}

#Docker related variables
variable "docker-network" {}

#Database Container related variables
variable "db-container-name" {}
variable "db-docker-image" {}
variable "db_software" {}
variable "db_driver_className" {}
variable "db_username" {}
variable "db_password" {}

#James Server related variables
variable "james_db_name" {}
variable "james-container-name" {}
variable "james-docker-image" {}
variable "james_s3_bucket_name" {}

#CRM related variables
variable "crm-container-name" {}
variable "crm-docker-image" {}
variable "crm-db-name" {}
variable "crm-volume-name" {}

module "file_gen_james_database_properties" {
  source = "../file_gen_james_database_properties"
  db_software           = var.db_software
  db-container-name     = var.db-container-name
  db_username           = var.db_username
  db_password           = var.db_password
  db_driver_className   = var.db_driver_className

  james_db_name         = var.james_db_name
}

module "file_gen_database_init" {
  source = "../file_gen_database_init"
  james_db_name = var.james_db_name
  crm_db_name   = var.crm-db-name
}

module "file_gen_pg_hba_conf" {
  source = "../file_gen_pg_hba_conf"
}

resource "local_file" "docker_compose_yml" {
  filename = "compose.yml"
  content  = <<EOF

name: Thusia

services:

  mysql:
    image: ${var.db-docker-image}
    container_name: ${var.db-container-name}
    restart: always
    volumes:
      - type: bind
        source: ${var.home-directory}database_init.sql
        target: /docker-entrypoint-initdb.d/database_init.sql
    environment:
      MYSQL_ROOT_PASSWORD: ${var.db_password}
      MYSQL_DATABASE: ${var.james_db_name}
      MYSQL_USER: ${var.db_username}
      MYSQL_PASSWORD: ${var.db_password}
    networks:
      - ${var.docker-network}

  james:
    image: ${var.james-docker-image}
    hostname: james.local
    container_name: ${var.james-container-name}
    restart: always
    volumes:
      - type: bind
        source: ${var.home-directory}james-database.properties
        target: /root/conf/james-database.properties

      - type: bind
        source: ${var.home-directory}mysql-jdbc-driver.jar
        target: /root/libs/database-jdbc-driver.jar

      - type: bind
        source: ${var.home-directory}keystore
        target: /root/conf/keystore

    networks:
      - ${var.docker-network}
    depends_on:
      - mysql

networks:
  ${var.docker-network}:

EOF
}



# suitecrm:
# image: ${var.crm-docker-image}
# container_name: ${var.crm-container-name}
# restart: always
# environment:
# DB_HOST: mysql
# DB_USER: db_user
# DB_PASSWORD: db_password
# DB_NAME: suitecrm_db
# networks:
# - ${var.docker-network}
# depends_on:
# - mysql
# - james