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


module "file_gen_pg_hba_conf" {
  source = "./file_gen_pg_hba_conf"
}

module "file_gen_james_database_properties" {
  source            = "./file_gen_james_database_properties"
  db-container-name = var.db-container-name
  db_username       = var.db_username
  db_password       = var.db_password
  db_name           = var.db_name
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


#XXXXXXXXXXXXXXXXXXXXXXXXXXXX Role, Policy, Profile XXXXXXXXXXXXXXXXXXXXXXXXXXXX
#TODO: the profile must be moved to a seprate module.
# Create an IAM profile for EC2 instance with S3 access
# 1st. we need to make the role.
resource "aws_iam_role" "ec2_role" {
  name               = "role_ec2_full_access_s3"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

}

# 2nd. we need to make the policy document. The policy document defines the entities 
# that the role can be assigned to. We want to assign this role to EC2
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 3rd. we define the permissions in the policy. Those that take the role
# can have full access to all S3 buckets. So we create IAM Policy 
# to give full access to S3 to the EC2 that assume this role.
resource "aws_iam_policy" "s3_full_access" {
  name        = "policy_s3_full_access"
  description = "A policy that allows full access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}

# 4th. at the end, we attach the policy to the role.
# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  policy_arn = aws_iam_policy.s3_full_access.arn
  role       = aws_iam_role.ec2_role.name
}

# 5th, EC2 cannot assume role, because it is not human. it instead can assume
# profile. so we make a profile and assign the role to the profile. the profile
# I guess can have more than one role.
# Create an IAM Instance Profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}



#______________________________        EC2          _____________________________
resource "aws_instance" "my_instance" {
  # ami           = data.aws_ami.my_ubuntu.id # Amazon Linux 2 AMI (Free Tier eligible)
  ami           = var.ec2-ami # Amazon Linux 2 AMI (Free Tier eligible)
  instance_type = "t2.micro"  # Free Tier eligible instance type

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
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
                sudo ${var.package-installer} install -y unzip

                #Installing AWS cli
                #sudo ${var.package-installer} install -y aws-cli    #aws-cli is pre-installed on amazon linux EC2

                # Verify unzip installation
                if ! command -v unzip &> /dev/null
                then
                    echo "unzip could not be installed" >&2
                    exit 1
                fi

                #Unzip the file
                #unzip ${var.home-directory}configfiles.zip -d ${var.home-directory}

                #download the JDBC driver
                curl --output ${var.home-directory}postgresql-42.7.5.jar ${var.jdbc-download-address}

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
                #Running the postgres container
                docker run --rm --name ${var.db-container-name} -e POSTGRES_DB=${var.db_name} -e POSTGRES_USER=${var.db_username} -e POSTGRES_PASSWORD=${var.db_password} --network ${var.docker-network} -d ${var.db-image}

                ###USING Apache James image
                docker run --rm --name james --hostname james.local -p80:80 -p25:25 -p110:110 -p143:143 -p465:465 -p587:587 -p993:993 -p8000:8000 -v /home/ec2-user/james-database.properties:/root/conf/james-database.properties -v /home/ec2-user/postgresql-42.7.5.jar:/root/libs/james-jdbc-driver.jar --network newnet apache/james:jpa-latest --generate-keystore

                #sudo docker run -v ${var.home-directory}james/postgres_driver/postgresql-42.7.5.jar:/root/conf/lib/postgresql-42.7.5.jar -v /${var.home-directory}/james/config_files/keystore:/root/conf/keystore --rm --name james -p110:110 -p25:25 -p431:431 -p8000:8000 --network newnet -d apache/james:jpa-3.6.1


                #docker run --rm --name postgres -e POSTGRES_DB=james -e POSTGRES_USER=james -e POSTGRES_PASSWORD=secret1 -p 5433:5432 --network newnet -d postgres:16.3
                #docker run --rm --name james --hostname james.local -p80:80 -p25:25 -p110:110 -p143:143 -p465:465 -p587:587 -p993:993 -p8000:8000 -v ./conf/james-database.properties:/root/conf/james-database.properties -v ./conf/lib/postgresql-42.7.5.jar:/root/libs/james-jdbc-driver.jar --network newnet apache/james:jpa-latest --generate-keystore

                #Running the apache webserver
                #-sudo docker run --rm --name web -p 80:80 -p443:443 -p8080:8080 -d httpd:2.4

              EOF
}
