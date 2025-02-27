# main.tf
provider "aws" {
  region = "us-east-1"
}

# Define the variable for vpc_id
variable "my_vpc_id" {
  description = "The ID of the VPC where the resources will be created"
  type        = string
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
  description = "The name for the postgres database."
  type        = string
}

# Create a security group to allow SSH, HTTP and HTTPS traffic
resource "aws_security_group" "http_https_ssh" {
  name        = "http-https-ssh-sg"
  description = "Allow SSH and HTTP and HTTPS traffic"
  vpc_id      = var.my_vpc_id  # Replace with your VPC ID

  # Inbound rule for HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mail_server" {
  name        = "smtp-imap-pop3-httprestapi-sg"
  description = "Allow SMTP, IMAP, POP3, and HTTP REST API traffic"
  vpc_id      = var.my_vpc_id  # Replace with your VPC ID

  # SMTP (Simple Mail Transfer Protocol) :
  # SMTP - sending email
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SMTP - submission for email clients that will submit messages for delivery
  ingress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IMAP (Internet Message Access Protocol) :
  # IMAP - standard IMAP connections
  ingress {
    from_port   = 143
    to_port     = 143
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # IMAP - IMAP over SSL/TLS
  ingress {
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # POP3 (Post Office Protocol) :
  # POP3 - standard POP3 connections
  ingress {
    from_port   = 110
    to_port     = 110
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # POP3 - POP3 over SSL/TLS
  ingress {
    from_port   = 995
    to_port     = 995
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (for REST APIs) :
  # HTTP - default port for HTTP services, including REST
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  # ami           = data.aws_ami.my_ubuntu.id # Amazon Linux 2 AMI (Free Tier eligible)
  ami          = "ami-05b10e08d247fb927" # Amazon Linux 2 AMI (Free Tier eligible)
  instance_type = "t2.micro"                # Free Tier eligible instance type

  # Associate the security group with the EC2 instance
  security_groups = [aws_security_group.http_https_ssh.name, aws_security_group.mail_server.name]
  key_name = "AccessKey"

  provisioner "file" {
      source      = "./configfiles.zip"
      destination = "/home/ec2-user/configfiles.zip"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./AccessKey.pem")
    host        = self.public_ip
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y

                #installing unzip
                sudo yum install -y unzip

                #Installing AWS cli
                #sudo yum install -y aws-cli

                # Verify unzip installation
                if ! command -v unzip &> /dev/null
                then
                    echo "unzip could not be installed" >&2
                    exit 1
                fi

                #Unzip the file
                unzip /home/ec2-user/configfiles.zip -d /home/ec2-user/

                #Installing and starting docker
                sudo yum install -y docker
                sudo service docker start
                sudo usermod -a -G docker ec2-user
                sudo docker network create newnet

                #Running the postgres container
                sudo docker run --rm --name post --network newnet -e POSTGRES_USER=${var.db_username} -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=${var.db_name}  -e PGDATA=/var/lib/postgresql/data/pgdata -v postgres_data:/var/lib/postgresql/data/pgdata -v /home/ec2-user/postgres/config_files/pg_hba.conf:/var/lib/postgresql/data/pg_hba.conf -d postgres:15.12

                #Running the james container
                  #USING Linagora image
                sudo docker run -v /home/ec2-user/james/postgres_driver/:/root/james-server-app-3.6.0-SNAPSHOT/conf/lib/ -v /home/ec2-user/james/config_files/james-database.properties:/root/james-server-app-3.6.0-SNAPSHOT/conf/james-database.properties --rm --name james -p110:110 -p25:25 -p431:431 -p8000:8000 --network newnet -d linagora/james-jpa-spring:branch-master
                  #USING Apache James image
                #sudo docker run -v /home/ec2-user/james/postgres_driver/:/root/conf/lib/ -v /home/ec2-user/james/config_files/keystore:/root/conf/keystore --rm --name james -p110:110 -p25:25 -p431:431 -p8000:8000 --network newnet -d apache/james:jpa-3.6.1

                #Running the apache webserver
                #sudo docker run --rm --name web -p 80:80 -p443:443 -p8080:8080 -d httpd:2.4

              EOF

  tags = {
    Name = "JamesMailServer"
  }
}
