variable "my_vpc_id" {
  description = "AWS account VPC_ID"
  type        = string
}

variable "crm_web_port_on_host" {
  description = "The port that the CRM web server will be accessible on the host machine"
  type        = string
}

variable "joomla_web_port_On_host" {
  description = "The port that the Joomla web server will be accessible on the host machine"
  type        = string
}

variable "rest_api_port_on_host" {
  description = "The port that the Rest-API server will be accessible on the host machine"
  type        = string
}

resource "aws_security_group" "http_https_ssh_database" {
  name        = "http_https_ssh_database_sg"
  description = "Allow SSH and HTTP and HTTPS traffic"
  vpc_id      = var.my_vpc_id # Replace with your VPC ID

  # Inbound rule for HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For the Apache James server REST APIs, we need to allow port 8000 ONLY IN DEBUG MODE.
  # The microservices can already communicate with James via Docker network.
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For the SUITECRM server, we need to allow port 8080 but since it is taken, we map it to 8086
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For the Joomla web server, we need to allow port 80 but since it is taken, we map it to 8081
  ingress {
    from_port   = var.joomla_web_port_On_host
    to_port     = var.joomla_web_port_On_host
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For our Rest-API server, we need to allow port 8080 but since it is taken, we map it to 8082
  ingress {
      from_port   = var.rest_api_port_on_host    // Port for the REST API server
      to_port     = var.rest_api_port_on_host
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.crm_web_port_on_host
    to_port     = var.crm_web_port_on_host
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow Mariadb port
  # ingress {
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
