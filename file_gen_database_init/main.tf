variable "james_db_name" {}
variable "james_db_username" {}
variable "james_db_password" {}

variable "crm_db_name" {}
variable "crm_db_username" {}
variable "crm_db_password" {}


resource "local_file" "database_init" {
  filename = "database_init.sql"
  content  = <<EOF
CREATE DATABASE ${var.james_db_name};
CREATE USER '${var.james_db_username}'@'%' IDENTIFIED BY '${var.james_db_password}';
GRANT ALL PRIVILEGES ON ${var.james_db_name}.* TO '${var.james_db_username}'@'%';


CREATE DATABASE ${var.crm_db_name};
CREATE USER '${var.crm_db_username}'@'%' IDENTIFIED BY '${var.crm_db_password}';
GRANT ALL PRIVILEGES ON ${var.crm_db_name}.* TO '${var.crm_db_username}'@'%';
EOF
}
