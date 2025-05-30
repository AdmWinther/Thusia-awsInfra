terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.23.0"
    }
  }
}
# main.tf
provider "aws" {
  region = "us-east-1"
}

locals {
  availability_zone = "us-east-1a"  # Replace with your desired availability zone
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
variable "db_root_password" {}
variable "db_driver_className" {}
variable "db_volume" {}

#James Server related variables
variable "james_db_name" {}
variable "james_db_username" {}
variable "james_db_password" {}
variable "james-container-name" {}
variable "james-docker-image" {}
variable "james_s3_bucket_name" {}

#AWS SES related variables
variable "aws_ses_mail_relay_address" {}
variable "aws_ses_mail_relay_port" {}
variable "aws_ses_smtp_relay_username" {}
variable "aws_ses_smtp_relay_password" {}

#Test and Demo emails password
variable "awin_password" {}
variable "crm_password" {}
variable "jpo_password" {}
variable "fbl_password" {}
variable "dmarc_reports_password" {}

variable "john_password" {}
variable "jane_password" {}
variable "test_password" {}
variable "demo_password" {}

#APACHE WEB related variables
variable "apache-docker-image" {}
variable "apache-container-name" {}


#CRM related variables
variable "crm-container-name" {}
variable "crm-docker-image" {}
variable "crm-db-name" {}
variable "crm-db-username" {}
variable "crm-db-password" {}
variable "crm_volume" {}
variable "crm_user_username" {}
variable "crm_user_password" {}


#Nginx related variables
variable "nginx-image" {}
variable "nginx-container-name" {}

#Rest-API related variables
variable "rest_api_db_name" {}
variable "rest_api_db_username" {}
variable "rest_api_db_password" {}

#AWS-EC2 related variables
variable "ec2-ami" {}
variable "home-directory" {}

#Elastic ip association_id
variable "eip_association_id" {}
variable "my_ip_address" {}

#EBC volume related variables
variable "volume-initialize" {
  type = bool
}
variable "volume-id" {}


#DNS related variables
variable "domain_name" {}
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    config file gen.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_docker_compose_yml" {
  source                = "./file_gen_docker_compose_yml"

  home-directory        = var.home-directory
  docker-network        = var.docker-network
  domain_name           = var.domain_name

  db_software           = var.db_software
  db-container-name     = var.db-container-name
  db-docker-image       = var.db-docker-image
  db_root_password      = var.db_root_password
  db_driver_className   = var.db_driver_className
  db_volume             = var.db_volume


  james-container-name  = var.james-container-name
  james-docker-image    = var.james-docker-image
  james_db_name               = var.james_db_name
  james_db_username           = var.james_db_username
  james_db_password           = var.james_db_password
  james_s3_bucket_name        = var.james_s3_bucket_name

  #AWS SES mail relay credentials
  aws_ses_mail_relay_address = var.aws_ses_mail_relay_address
  aws_ses_mail_relay_port    = var.aws_ses_mail_relay_port
  aws_ses_smtp_relay_username = var.aws_ses_smtp_relay_username
  aws_ses_smtp_relay_password = var.aws_ses_smtp_relay_password

  #Test and demo emails password
  awin_password        = var.awin_password
  crm_password         = var.crm_password
  jpo_password         = var.jpo_password
  fbl_password         = var.fbl_password

  dmarc_reports_password = var.dmarc_reports_password
  john_password        = var.john_password
  jane_password        = var.jane_password
  test_password        = var.test_password
  demo_password        = var.demo_password

  crm-container-name    = var.crm-container-name
  crm-docker-image      = var.crm-docker-image
  crm-db-name           = var.crm-db-name
  crm-db-username       = var.crm-db-username
  crm-db-password       = var.crm-db-password
  crm_volume            = var.crm_volume
  crm_user_username     = var.crm_user_username
  crm_user_password     = var.crm_user_password

  nginx-image = var.nginx-image
  nginx-container-name = var.nginx-container-name
  my_ip_address = var.my_ip_address

  rest_api_db_name           = var.rest_api_db_name
  rest_api_db_username       = var.rest_api_db_username
  rest_api_db_password       = var.rest_api_db_password

  volume-initialize     = var.volume-initialize
}


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    Security Grp.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Create a security group to allow SSH, HTTP and HTTPS traffic
module "sec_grp_http_https_ssh_database" {
  source    = "./sec_grp_http_https_ssh_database"
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
  #instance_type = "t2.micro"
  availability_zone = local.availability_zone


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./AccessKey.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "THUSIA-V1"
  }

  # iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  iam_instance_profile = module.profile_gen_EC2_full_Access_to_S3.ec2_full_access_to_s3_bucket_profile_name
  # Associate the security group with the EC2 instance
  security_groups = [module.sec_grp_http_https_ssh_database.sec_grp_name, module.sec_grp_mail_server.sec_grp_name]
  key_name        = "AccessKey"

  # Copy some files into the EC2
  provisioner "file" {
    source      = "./james-database.properties"
    destination = "/${var.home-directory}james-database.properties"
  }

  provisioner "file" {
    source      = "./compose.yml"
    destination = "/${var.home-directory}compose.yml"
  }

  provisioner "file" {
    source      = "./jdbc.jar"
    destination = "/${var.home-directory}jdbc.jar"
  }

  provisioner "file" {
    source      = "./keystore_ca"
    destination = "/${var.home-directory}keystore_ca"
  }

  provisioner "file" {
    source      = "./database_init.sql"
    destination = "/${var.home-directory}database_init.sql"
  }

  provisioner "file" {
    source      = "./nginx.conf"
    destination = "/${var.home-directory}nginx.conf"
  }

  provisioner "file" {
    source      = "./hosts"
    destination = "/${var.home-directory}hosts"
  }

  provisioner "file" {
    source      = "./smtpserver.xml"
    destination = "/${var.home-directory}smtpserver.xml"
  }

  provisioner "file" {
    source      = "./imapserver.xml"
    destination = "/${var.home-directory}imapserver.xml"
  }

  provisioner "file" {
    source      = "./james_initialize.sh"
    destination = "/${var.home-directory}james_initialize.sh"
  }

  provisioner "file" {
    source      = "./mailetcontainer.xml"
    destination = "/${var.home-directory}mailetcontainer.xml"
  }

  provisioner "file" {
    source      = "./crm_initialize.sh"
    destination = "/${var.home-directory}crm_initialize.sh"
  }

    provisioner "file" {
        source      = "./SSL-certificates/crm.awin.dk/crm_https_ssl_certificate.crt"
        destination = "/${var.home-directory}crm_https_ssl_certificate.crt"
    }

    provisioner "file" {
      source      = "./SSL-certificates/crm.awin.dk/crm_https_ssl_chain_certificate.crt"
      destination = "/${var.home-directory}crm_https_ssl_chain_certificate.crt"
    }

    provisioner "file" {
      source = "./SSL-certificates/crm.awin.dk/crm_https_ssl_private_key.key"
        destination = "/${var.home-directory}crm_https_ssl_private_key.key"
    }


  user_data = <<-EOF
                #!/bin/bash
                set -x
                sudo ${var.package-installer} update -y


                #downloading and installing AWS Mountpoint. #Mountpoint is used for mounting S3 into the EC2
                sudo mkdir ${var.home-directory}mount-install-source/
                sudo wget -P ${var.home-directory}mount-install-source/ https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
                sudo ${var.package-installer} install -y ${var.home-directory}mount-install-source/mount-s3.rpm

                #Installing and starting docker
                sudo ${var.package-installer} install -y docker
                sudo service docker start
                sudo usermod -a -G docker ec2-user
                sudo docker network create ${var.docker-network}

                #Installing docker-compose
                sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose

                # mount the bucket
                sudo mkdir ${var.home-directory}bucket/
                sudo mount-s3 ${var.james_s3_bucket_name} ${var.home-directory}bucket/

                #Make a directory to mount all of the volumes in it.
                sudo mkdir ${var.home-directory}volumes/

                # Wait for the device to be available
                while [ ! -e /dev/xvdf ]; do
                  echo "Waiting for /dev/xvdf to be available..."
                  sleep 5
                done

                #format the attached EBS volume only if variable "volume-initialize" is set to true
                ${!var.volume-initialize ? "#": ""} sudo mkfs -t ext4 /dev/xvdf

                # mount the EBS volume into the EC2
                sudo mount /dev/xvdf ${var.home-directory}volumes/

                #Copy the file hosts to /etc/hosts. This requires SUDO access therefore could not be done via provisioning.
                sudo cp ${var.home-directory}hosts /etc/hosts

                #It is not a must to create the folders for mouting into container. Docker make the folders if they do not exist.
                #This musr run only if it is the initialize mode: only if the variable "volume-initialize" is set to true
                #Follwing volumes are needed
                    # mariadb
                    # james
                    # certbot-etc
                    # certbot-var
                ${!var.volume-initialize ? "#": ""} sudo mkdir ${var.home-directory}volumes/${var.db_volume}/
                ${!var.volume-initialize ? "#": ""} sudo mkdir ${var.home-directory}volumes/${var.crm_volume}/

                #To avoid an error, first one should make the folder for database persistant data before give the ownership to mysql.
                #give the ownership fo the docker volume for database to mysql. MySQL needs it to write data into the volume.
                sudo chown -R 999:999 ${var.home-directory}volumes/${var.db_volume}/

                #Run the containers
                #It is important to run this command with (-d) to detach, otherwise the rest of the initializers will not execute.
                docker-compose -f ${var.home-directory}compose.yml up -d

                #Inform the user that you are waiting for the containers to be up and running
                #The following initializers will be executed only if the server is being initialized.
                ${!var.volume-initialize ? "#": ""}echo "Waiting for the containers to be up and running..."
                ${!var.volume-initialize ? "#": ""}sudo mkdir ${var.home-directory}d01_wait_60_sec/
                ${!var.volume-initialize ? "#": ""}# Wait for 60 seconds before running the initializers in CRM container.
                ${!var.volume-initialize ? "#": ""}sleep 60
                ${!var.volume-initialize ? "#": ""}echo "Containers are up and running. end of 60 seconds."

                #${!var.volume-initialize ? "#": ""}sudo cp ${var.home-directory}crm_initialize.sh ${var.home-directory}crmcrm.sh
                ${!var.volume-initialize ? "#": ""}sudo chmod +x ${var.home-directory}crm_initialize.sh
                ${!var.volume-initialize ? "#": ""}echo "Running the initializer in the CRM container..."
                ${!var.volume-initialize ? "#": ""}sudo bash ${var.home-directory}crm_initialize.sh

                ${!var.volume-initialize ? "#": ""}sudo chmod +x ${var.home-directory}james_initialize.sh
                ${!var.volume-initialize ? "#": ""}echo "Running the initializer in the JAMES container..."
                ${!var.volume-initialize ? "#": ""}sudo bash ${var.home-directory}james_initialize.sh
                ${!var.volume-initialize ? "#": ""}sudo mkdir ${var.home-directory}d99_initialize_finished/

                echo "Thusia server setup cmpleted."
              EOF
}

resource "aws_volume_attachment" "Thusia_data" {
  device_name = "/dev/sdf"  # The device name you want to use (e.g., /dev/sdf)
  volume_id   = var.volume-id  # Replace with your EBS volume ID
  instance_id = aws_instance.my_instance.id

  # Ensure that the attachment waits for the instance to be ready.
  depends_on = [aws_instance.my_instance]
}

output "ssh_connection_string" {
  value = "ssh -i AccessKey.pem ec2-user@awin.dk"
}

output "server_domain" {
  value = aws_instance.my_instance.public_dns
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.my_instance.id
  allocation_id = var.eip_association_id
}