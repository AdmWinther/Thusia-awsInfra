# main.tf
provider "aws" {
  region = "us-east-1"
}

# Define the variables
variable "my_vpc_id" {
  description = "The ID of the VPC where the resources will be created"
  type        = string
}

variable "db-container-name" {
  description = "the name of the container for the database."
  type        = string
}

variable "db-image" {
  description = "the image used for making the postgres container"
  type        = string
}

variable "database_platform" {
  description = "The platform of the database, for example: MySQL, PostgresSQL, etc."
}

variable "db_driver_className" {
  description = "The class name of the JDBC driver."
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

variable "james-container-name" {}
variable "james-image" {}

variable "docker-network" {
  description = "The name for the docker network."
  type        = string
}

variable "james_s3_bucket_name" {
  description = "The name for the S3 bucket."
  type        = string
}

variable "ec2-ami" {
  description = "the ami used for making the ec2"
  type        = string
}

variable "package-installer" {
  description = "the package manager for EC2. It can be yum or apt-get, depending on the EC2 ami and operating system"
  type        = string
}

variable "home-directory" {
  description = "The home directory of the EC2, depending on the AMI it can be either /root/ubuntu/ or /home/ec2-user/"
  type        = string
}

variable "jdbc-download-address" {
  description = "The url for downloading the jdbc driver"
  type        = string
}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  config file gen.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_pg_hba_conf" {
  source = "./file_gen_pg_hba_conf"
}

module "file_gen_james_database_properties" {
  source                = "./file_gen_james_database_properties"
  database_platform     = var.database_platform
  db-container-name     = var.db-container-name
  db_username           = var.db_username
  db_password           = var.db_password
  db_name               = var.db_name
  db_driver_className   = var.db_driver_className
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
#TODO: the profile must be moved to a separate module.
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

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./AccessKey.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "V2.James"
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo ${var.package-installer} update -y

                #installing unzip
                #Unzip is not needed. Files are unzipped and placed in the S3 bucket.
                # sudo ${var.package-installer} install -y unzip

                #Installing AWS cli
                #sudo ${var.package-installer} install -y aws-cli    #aws-cli is pre-installed on amazon linux EC2

                # Verify unzip installation
                #Unzip is not needed. Files are unzipped and placed in the S3 bucket.
                # if ! command -v unzip &> /dev/null
                # then
                #     echo "unzip could not be installed" >&2
                #     exit 1
                # fi

                #Unzip the file
                #unzip ${var.home-directory}configfiles.zip -d ${var.home-directory}

                #download the JDBC driver
                #This step is not needed. The JDBC driver is downloaded and placed in the S3 bucket
                #curl --output ${var.home-directory}postgresql-42.7.5.jar ${var.jdbc-download-address}

                #downloading and installing AWS Mountpoint
                #Mountpoint is used for mounting S3 into the EC2
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
                
                sudo -s
                #MySQL
                docker run --rm --name ${var.db-container-name} -e MYSQL_DATABASE=${var.db_name} -e MYSQL_ROOT_PASSWORD=${var.db_password} -e MYSQL_USER=${var.db_username} -e MYSQL_PASSWORD=${var.db_password} --network ${var.docker-network} -d ${var.db-image}

                #USING Apache James image-with keystore
                docker run --rm --name ${var.james-container-name} --hostname james.local -v ${var.home-directory}james-database.properties:/root/conf/james-database.properties -v ${var.home-directory}bucket/jdbc-driver/mysql-jdbc-driver.jar:/root/libs/database-jdbc-driver.jar -v ${var.home-directory}bucket/james-keystore/keystore:/root/conf/keystore --network ${var.docker-network} -d ${var.james-image}
              EOF
}
