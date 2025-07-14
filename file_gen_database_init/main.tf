variable "james_db_name" {}
variable "james_db_username" {}
variable "james_db_password" {}

variable "crm_db_name" {}
variable "crm_db_username" {}
variable "crm_db_password" {}

variable "joomla_db_name" {}
variable "joomla_db_username" {}
variable "joomla_db_password" {}

variable "rest_api_db_name" {}
variable "rest_api_db_username" {}
variable "rest_api_db_password" {}

resource "local_file" "database_init" {
  filename = "database_init.sql"
  content  = replace(<<EOF

-- Create databases and users for Apache James, set username and password
CREATE DATABASE ${var.james_db_name};
CREATE USER '${var.james_db_username}'@'%' IDENTIFIED BY '${var.james_db_password}';
GRANT ALL PRIVILEGES ON ${var.james_db_name}.* TO '${var.james_db_username}'@'%';

-- Create databases and users for SuiteCRM, set username and password
CREATE DATABASE ${var.crm_db_name};
CREATE USER '${var.crm_db_username}'@'%' IDENTIFIED BY '${var.crm_db_password}';
GRANT ALL PRIVILEGES ON ${var.crm_db_name}.* TO '${var.crm_db_username}'@'%';

-- Create databases and users for Joomla, set username and password
CREATE DATABASE ${var.joomla_db_name};
CREATE USER '${var.joomla_db_username}'@'%' IDENTIFIED BY '${var.joomla_db_password}';
GRANT ALL PRIVILEGES ON ${var.joomla_db_name}.* TO '${var.joomla_db_username}'@'%';

-- Create databases and users for RESTApi, set username and password
CREATE DATABASE ${var.rest_api_db_name};
CREATE USER '${var.rest_api_db_username}'@'%' IDENTIFIED BY '${var.rest_api_db_password}';
GRANT ALL PRIVILEGES ON ${var.rest_api_db_name}.* TO '${var.rest_api_db_username}'@'%';
CREATE TABLE ${var.rest_api_db_name}.registered (
    id int AUTO_INCREMENT NOT NULL,
    username VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    last_update DATETIME NOT NULL,
    PRIMARY KEY (id)
);
INSERT INTO ${var.rest_api_db_name}.registered (username, status, last_update) VALUES ('admin@localhost', 'active', '2025-04-06 14:30:00');
INSERT INTO ${var.rest_api_db_name}.registered (username, status, last_update) VALUES ('scam@localhost', 'failed', '2025-04-06 14:35:00');
EOF
    , "\r", "")
}