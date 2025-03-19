variable "database_platform" {
  description = "The platform used for the database, for example, MySQL or PostgreSQL"
}

variable "db_username" {
  description = "The username for the postgres database which is being made inside the EC2 instance docker image."
  type        = string
}

variable "db_password" {
  description = "The password for the postgres database which is being made inside the EC2 instance docker image."
  type        = string
}

variable "db_name" {
  description = "The name for the database which is being made inside the EC2 instance docker image."
  type        = string
}

variable "db-container-name" {
  description = "The name of the container for the database"
}

variable "db_driver_className" {
  description = "The name of the JDBC driver class"
}


resource "local_file" "james_database_properties_file" {
  filename = "james-database.properties"
  content  = <<EOF
database.driverClassName=${var.db_driver_className}
database.url=jdbc:${var.database_platform}://${var.db-container-name}/${var.db_name}
database.username=${var.db_username}
database.password=${var.db_password}
EOF
}
