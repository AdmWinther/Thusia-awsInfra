variable "db_software" {}
variable "db_username" {}
variable "db_password" {}
variable "james_db_name" {}
variable "db-container-name" {}
variable "db_driver_className" {}


resource "local_file" "james_database_properties_file" {
  filename = "james-database.properties"
  content  = <<EOF
database.driverClassName=${var.db_driver_className}
database.url=jdbc:${var.db_software}://${var.db-container-name}/${var.james_db_name}
database.username=${var.db_username}
database.password=${var.db_password}
EOF
}
