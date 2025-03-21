# main.tf
provider "aws" {
  region = "us-east-1"
}

# Define the variables. The variables are defined in the terraform.tfvars file
#AWS related variables
variable "my_vpc_id" {}

#Docker related variables
variable "docker-network" {}
variable "package-installer" {}

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


#AWS-EC2 related variables
variable "ec2-ami" {}
variable "home-directory" {}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  config file gen.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_docker_compose_yml" {
  source                = "./file_gen_docker_compose_yml"

  home-directory        = var.home-directory
  docker-network        = var.docker-network

  db_software           = var.db_software
  db-container-name     = var.db-container-name
  db_username           = var.db_username
  db_password           = var.db_password
  db_driver_className   = var.db_driver_className
  db-docker-image       = var.db-docker-image


  james-container-name  = var.james-container-name
  james-docker-image    = var.james-docker-image
  james_db_name               = var.james_db_name
  james_s3_bucket_name        = var.james_s3_bucket_name

  crm-container-name    = var.crm-container-name
  crm-docker-image      = var.crm-docker-image
  crm-db-name           = var.crm-db-name
  crm-volume-name       = var.crm-volume-name
}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    Security Grp.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Create a security group to allow SSH, HTTP and HTTPS traffic
module "sec_grp_http_https_ssh" {
  source    = "./sec_grp_http_https_ssh"
  my_vpc_id = var.my_vpc_id
}
module "sec_grp_mail_server" {
  source    = "./sec_grp_mail_server"
  my_vpc_id = var.my_vpc_id
}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXX Role, Policy, Profile  XXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "profile_gen_EC2_full_Access_to_S3" {
  source = "./profile_gen_EC2FullAccessToS3Bucket"
}


#______________________________        EC2          _____________________________
resource "aws_instance" "my_instance" {
  ami           = var.ec2-ami
  instance_type = "t2.small"

  # iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  iam_instance_profile = module.profile_gen_EC2_full_Access_to_S3.ec2_full_access_to_s3_bucket_profile_name
  # Associate the security group with the EC2 instance
  security_groups = [module.sec_grp_http_https_ssh.sec_grp_name, module.sec_grp_mail_server.sec_grp_name]
  key_name        = "AccessKey"

  # Copy some files into the EC2
  provisioner "file" {
    source      = "./james-database.properties"
    destination = "/${var.home-directory}/james-database.properties"
  }

  provisioner "file" {
    source      = "./pg_hba.conf"
    destination = "/${var.home-directory}/pg_hba.conf"
  }

  provisioner "file" {
    source      = "./compose.yml"
    destination = "/${var.home-directory}/compose.yml"
  }

  provisioner "file" {
    source      = "./mysql-jdbc-driver.jar"
    destination = "/${var.home-directory}/mysql-jdbc-driver.jar"
  }

  provisioner "file" {
    source      = "./keystore"
    destination = "/${var.home-directory}/keystore"
  }

  provisioner "file" {
    source      = "./database_init.sql"
    destination = "/${var.home-directory}/database_init.sql"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./AccessKey.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "THUSIA-V1"
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo ${var.package-installer} update -y


                #downloading and installing AWS Mountpoint. #Mountpoint is used for mounting S3 into the EC2
                sudo mkdir ${var.home-directory}mount-install-source/
                sudo wget -P ${var.home-directory}mount-install-source/ https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
                sudo ${var.package-installer} install -y ${var.home-directory}mount-install-source/mount-s3.rpm

                # mount the bucket
                sudo mkdir ${var.home-directory}bucket/
                sudo mount-s3 ${var.james_s3_bucket_name} ${var.home-directory}bucket/


                #Installing and starting docker
                sudo ${var.package-installer} install -y docker
                sudo service docker start
                sudo usermod -a -G docker ubuntu
                sudo docker network create ${var.docker-network}

                #Installing docker-compose
                sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose

                sudo -s
                cp ${var.home-directory}bucket/jdbc-driver/${var.db_software}-jdbc-driver.jar ${var.docker-network}jdbc-driver.jar
                cp ${var.home-directory}bucket/james-keystore/keystore ${var.docker-network}keystore

                #MySQL
                #docker run --rm --name ${var.db-container-name} -e MYSQL_DATABASE=${var.james_db_name} -e MYSQL_ROOT_PASSWORD=${var.db_password} -e MYSQL_USER=${var.db_username} -e MYSQL_PASSWORD=${var.db_password} --network ${var.docker-network} -d ${var.db-docker-image}

                #USING Apache James image-with keystore
                #docker run --rm --name ${var.james-container-name} --hostname james.local -v ${var.home-directory}james-database.properties:/root/conf/james-database.properties -v ${var.home-directory}bucket/jdbc-driver/${var.db_software}-jdbc-driver.jar:/root/libs/database-jdbc-driver.jar -v ${var.home-directory}bucket/james-keystore/keystore:/root/conf/keystore --network ${var.docker-network} -d ${var.james-docker-image}

                #SuiteCRM
                #docker volume create --name ${var.crm-volume-name}
                #docker run --rm --name ${var.crm-container-name} -e MYSQL_ROOT_PASSWORD=${var.db_password} -e MYSQL_USER=${var.db_username} -e MYSQL_PASSWORD=${var.db_password} --network ${var.docker-network} -d ${var.crm-docker-image}

              EOF
}

output "ssh_connection_string" {
  value = "ssh -i ${"AccessKey.pem"} ec2-user@${aws_instance.my_instance.public_ip}"
}