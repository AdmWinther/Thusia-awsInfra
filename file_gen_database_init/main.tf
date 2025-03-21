variable "james_db_name" {}
variable "crm_db_name" {}


resource "local_file" "database_init" {
  filename = "database_init.sql"
  content  = <<EOF
CREATE DATABASE ${var.crm_db_name};
EOF
}
