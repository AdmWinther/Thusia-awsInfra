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
variable "admin_password" {}
variable "awin_password" {}
variable "crm_password" {}
variable "joomla_password" {}
variable "api_joomla_password" {}
variable "wordpress_password" {}
variable "jpo_password" {}
variable "fbl_password" {}
variable "dmarc_reports_password" {}

variable "john_password" {}
variable "jane_password" {}
variable "test_password" {}
variable "demo_password" {}

#CRM related variables
variable "crm-container-name" {}
variable "crm-docker-image" {}
variable "suitecrm_image_home_directory" {}
variable "crm_exposed_port_of_container_for_web" {}
variable "crm_web_port_on_host" {}
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
variable "rest_api_port_on_host" {}
variable "CRM_API_AuthenticationClientId" {}
variable "CRM_API_AuthenticationClientSecret" {}
variable "JOOMLA_API_TOKEN"{}


variable "rest_api_docker_image" {}
variable "rest-api-container-name" {
    type = string
}

#Joomla  related variables
variable "joomla_db_name" {}
variable "joomla_db_username" {}
variable "joomla_db_password" {}
variable "joomla-container-name" {}
variable "joomla-docker-image" {}
variable "joomla_volume" {}
variable "joomla_web_port_On_host" {}
variable "joomla_max_package_size" {}

#Wordpress related variables
variable "wordpress-container-name" {}
variable "wordpress-docker-image" {}
variable "wordpress_db_name" {}
variable "wordpress_db_username" {}
variable "wordpress_db_password" {}
variable "wordpress_volume" {}

#AWS-EC2 related variables
variable "ec2-ami" {}
variable "home-directory" {}

#Elastic ip association_id
variable "eip_association_id" {}
variable "my_ip_address" {}

#EBC volume related variables
variable "container_volume_initialize" {
    type = bool
}
variable "containers_volume_id" {}


#****variable "refresh_docker_images" {
#****    type = bool
#****}
#****variable "docker_images_volume_id" {}

#DNS related variables
variable "domain_name" {}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    FILE GENERATOR   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    DOCKER COMPOSE file gen.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_docker_compose_yml" {
    source                = "./___ShredModules___/file_gen_docker_compose_yml"

    home-directory        = var.home-directory
    docker-network        = var.docker-network

    db-container-name     = var.db-container-name
    db-docker-image       = var.db-docker-image
    db_root_password      = var.db_root_password
    db_volume             = var.db_volume


    james-container-name  = var.james-container-name
    james-docker-image    = var.james-docker-image

    crm-container-name    = var.crm-container-name
    crm-docker-image      = var.crm-docker-image
    crm-db-name           = var.crm-db-name
    crm-db-username       = var.crm-db-username
    crm-db-password       = var.crm-db-password
    crm_volume            = var.crm_volume
    crm_user_username     = var.crm_user_username
    crm_user_password     = var.crm_user_password
    crm_exposed_port_of_container_for_web = var.crm_exposed_port_of_container_for_web
    crm_web_port_on_host = var.crm_web_port_on_host

    nginx-image = var.nginx-image
    nginx-container-name = var.nginx-container-name

    joomla-container-name  = var.joomla-container-name
    joomla-docker-image    = var.joomla-docker-image
    joomla_db_name         = var.joomla_db_name
    joomla_db_username     = var.joomla_db_username
    joomla_db_password     = var.joomla_db_password
    joomla_volume          = var.joomla_volume
    joomla_web_port_on_host = var.joomla_web_port_On_host

    rest-api-container-name = var.rest-api-container-name
    rest_api_docker_image   = var.rest_api_docker_image
    rest_api_port_on_host   = var.rest_api_port_on_host
    CRM_API_AuthenticationClientId = var.CRM_API_AuthenticationClientId
    CRM_API_AuthenticationClientSecret = var.CRM_API_AuthenticationClientSecret
    JOOMLA_API_TOKEN = var.JOOMLA_API_TOKEN

    wordpress-container-name = var.wordpress-container-name
    wordpress-docker-image   = var.wordpress-docker-image
    wordpress_db_name        = var.wordpress_db_name
    wordpress_db_username    = var.wordpress_db_username
    wordpress_db_password    = var.wordpress_db_password
    wordpress_volume         = var.wordpress_volume

    volume-initialize     = var.container_volume_initialize
}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    Database CONFIG FILEs GENERATOR    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_database_init" {
    source = "./___ShredModules___/file_gen_database_init"
    james_db_name = var.james_db_name
    james_db_username = var.james_db_username
    james_db_password = var.james_db_password

    crm_db_name   = var.crm-db-name
    crm_db_username   = var.crm-db-username
    crm_db_password   = var.crm-db-password

    joomla_db_name = var.joomla_db_name
    joomla_db_username = var.joomla_db_username
    joomla_db_password = var.joomla_db_password

    wordpress_db_name = var.wordpress_db_name
    wordpress_db_username = var.wordpress_db_username
    wordpress_db_password = var.wordpress_db_password

    rest_api_db_name   = var.rest_api_db_name
    rest_api_db_username   = var.rest_api_db_username
    rest_api_db_password   = var.rest_api_db_password
}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    SuiteCRM CONFIG FILEs GENERATOR    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_crm_initialize_sh" {
    source = "./___ShredModules___/file_gen_crm_initialize_sh"
    suitecrm_image_home_directory = var.suitecrm_image_home_directory
}
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    JAMES CONFIG FILEs GENERATOR    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_james_database_properties" {
    source = "./___ShredModules___/file_gen_james_database_properties"
    db_software           = var.db_software
    db-container-name     = var.db-container-name
    james_db_username           = var.james_db_username
    james_db_password           = var.james_db_password
    db_driver_className   = var.db_driver_className

    james_db_name         = var.james_db_name
}

module "file_gen_james_initialize_sh" {
    source = "./___ShredModules___/file_gen_james_initialize_sh"
    admin_password          = var.admin_password
    awin_password           = var.awin_password
    jpo_password            = var.jpo_password
    joomla_password         = var.joomla_password
    wordpress_password      = var.wordpress_password
    api_joomla_password     = var.api_joomla_password
    fbl_password            = var.fbl_password
    dmarc_reports_password  = var.dmarc_reports_password

    john_password           = var.john_password
    jane_password           = var.jane_password
    test_password           = var.test_password
    demo_password           = var.demo_password
    crm_password            = var.crm_password
}

module "file_gen_james_imapserver_xml" {
    source = "./___ShredModules___/file_gen_james_imapserver_xml"
}

module "file_gen_smtpserver_xml" {
    source = "./___ShredModules___/file_gen_james_smtpserver_xml"
}

module "file_gen_mailetcontainer_xml" {
    source = "./___ShredModules___/file_gen_james_mailetcontainer_xml"

    aws_ses_mail_relay_address = var.aws_ses_mail_relay_address
    aws_ses_mail_relay_port = var.aws_ses_mail_relay_port
    domain_name = var.domain_name
    aws_ses_smtp_relay_username = var.aws_ses_smtp_relay_username
    aws_ses_smtp_relay_password = var.aws_ses_smtp_relay_password
}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    NGINX CONFIG FILEs GENERATOR    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_nginx_conf" {
    source = "./___ShredModules___/file_gen_nginx_nginx_conf"
    crm_container_name = var.crm-container-name
    crm_exposed_port_of_container_for_web = var.crm_exposed_port_of_container_for_web
    joomla-container-name = var.joomla-container-name
    rest_api_port_on_host = var.rest_api_port_on_host
    rest-api-container-name = var.rest-api-container-name
    domain_name = var.domain_name
}

module "file_gen_etc_hosts" {
    source = "./___ShredModules___/file_gen_etc_hosts"
    domain_name = var.domain_name
}

module "file_gen_SSL_Agent" {
    source = "./___ShredModules___/file_gen_SSL_Agent"
    domain_name = var.domain_name
    package-installer = var.package-installer
}
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    JOOMLA CONFIG FILEs GENERATOR    XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "file_gen_joomla_php_ini" {
    source = "./___ShredModules___/file_gen_joomla_php_ini"
    joomla_max_package_size = var.joomla_max_package_size
}

module "file_gen_joomla_dot_htaccess" {
    source = "./___ShredModules___/file_gen_joomla_dot_htaccess"
}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    Security Grp.    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Create a security group to allow SSH, HTTP and HTTPS traffic
module "sec_grp_http_https_ssh_database" {
    source    = "./sec_grp_http_https_ssh_database"
    my_vpc_id = var.my_vpc_id
    crm_web_port_on_host = var.crm_web_port_on_host
    joomla_web_port_On_host = var.joomla_web_port_On_host
    rest_api_port_on_host = var.rest_api_port_on_host
}
module "sec_grp_mail_server" {
    source    = "./sec_grp_mail_server"
    my_vpc_id = var.my_vpc_id
}

#XXXXXXXXXXXXXXXXXXXXXXXXXXXX Role, Policy, Profile  XXXXXXXXXXXXXXXXXXXXXXXXXXXX
module "profile_gen_EC2_full_Access_to_S3_and_SES" {
    source = "./profile_gen_EC2FullAccessToS3BucketAndSES"
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

    iam_instance_profile = module.profile_gen_EC2_full_Access_to_S3_and_SES.ec2_full_access_to_s3_bucket_and_ses_profile_name
    # Associate the security group with the EC2 instance
    security_groups = [module.sec_grp_http_https_ssh_database.sec_grp_name, module.sec_grp_mail_server.sec_grp_name]
    key_name        = "AccessKey"

    # Copy some files into the EC2
//####################################################################################
    //Provisioning Database configuration files
    provisioner "file" {
        source      = "./james-database.properties"
        destination = "/${var.home-directory}james-database.properties"
    }

    provisioner "file" {
        source      = "./jdbc.jar"
        destination = "/${var.home-directory}jdbc.jar"
    }
    provisioner "file" {
        source      = "./database_init.sql"
        destination = "/${var.home-directory}database_init.sql"
    }
    //####################################################################################
    //###################  Provisioning James Mail Server configuration files  ###########
    //####################################################################################

    provisioner "file" {
        source      = "./SSL-certificates/keystore"
        destination = "/${var.home-directory}keystore"
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
        source      = "./mailetcontainer.xml"
        destination = "/${var.home-directory}mailetcontainer.xml"
    }

    provisioner "file" {
        source      = "./james_initialize.sh"
        destination = "/${var.home-directory}james_initialize.sh"
    }
    //####################################################################################
    //#####################  Provisioning SuiteCRM files  ##################
    //####################################################################################
    provisioner "file" {
        source      = "./crm_initialize.sh"
        destination = "/${var.home-directory}crm_initialize.sh"
    }

    provisioner "file" {
        source      = "./SSL_Agent.sh"
        destination = "/${var.home-directory}SSL_Agent.sh"
    }

    provisioner "file" {
        source      = "./SSL-certificates/fullchain.pem"
        destination = "/${var.home-directory}fullchain.pem"
    }

    provisioner "file" {
        source      = "./SSL-certificates/chain.pem"
        destination = "/${var.home-directory}chain.pem"
    }

    provisioner "file" {
        source      = "./SSL-certificates/cert.pem"
        destination = "/${var.home-directory}cert.pem"
    }

    provisioner "file" {
        source      = "./SSL-certificates/privkey.pem"
        destination = "/${var.home-directory}privkey.pem"
    }
    # provisioner "file" {
    #     source      = "./SSL-certificates/crm.awin.dk/crm_https_ssl_certificate.pem"
    #     destination = "/${var.home-directory}crm_https_ssl_certificate.pem"
    # }
    #
    # provisioner "file" {
    #     source      = "./SSL-certificates/crm.awin.dk/crm_https_ssl_chain_certificate.pem"
    #     destination = "/${var.home-directory}crm_https_ssl_chain_certificate.pem"
    # }
    #
    # provisioner "file" {
    #     source = "./SSL-certificates/crm.awin.dk/crm_https_ssl_private_key.pem"
    #     destination = "/${var.home-directory}crm_https_ssl_private_key.pem"
    # }
    #
    # provisioner "file" {
    #     source = "./SSL-certificates/crm.awin.dk/crm_https_ssl_fullchain.pem"
    #     destination = "/${var.home-directory}crm_https_ssl_fullchain.pem"
    # }
    //####################################################################################
    //#####################  Provisioning Nginx configuration files  #####################
    //####################################################################################

    provisioner "file" {
        source      = "./nginx.conf"
        destination = "/${var.home-directory}nginx.conf"
    }

    provisioner "file" {
        source      = "./hosts"
        destination = "/${var.home-directory}hosts"
    }
    //####################################################################################
    //#####################  Provisioning Joomla configuration files  #####################
    //####################################################################################
    provisioner "file" {
        source = "./php.ini"
        destination = "/${var.home-directory}php.ini"
    }

    provisioner "file" {
        source = "./.htaccess"
        destination = "/${var.home-directory}.htaccess"
    }

    # provisioner "file" {
    #     source      = "./SSL-certificates/awin.dk_and_www.awin.dk/www_https_ssl_fullchain.pem"
    #     destination = "/${var.home-directory}www_https_ssl_fullchain.pem"
    # }
    #
    # provisioner "file" {
    #     source = "./SSL-certificates/awin.dk_and_www.awin.dk/www_https_ssl_private_key.pem"
    #     destination = "/${var.home-directory}www_https_ssl_private_key.pem"
    # }


    //####################################################################################
    //#####################  Provisioning REST_API container files   #####################
    //####################################################################################

    # provisioner "file" {
    #     source      = "./SSL-certificates/api.awin.dk/api_https_ssl_fullchain.pem"
    #     destination = "/${var.home-directory}api_https_ssl_fullchain.pem"
    # }
    #
    # provisioner "file" {
    #     source = "./SSL-certificates/api.awin.dk/api_https_ssl_private_key.pem"
    #     destination = "/${var.home-directory}api_https_ssl_private_key.pem"
    # }


    //####################################################################################
    //#####################  Provisioning the docker-compose.yml file  ###################
    //####################################################################################

    provisioner "file" {
        source      = "./compose.yml"
        destination = "/${var.home-directory}compose.yml"
    }

    //####################################################################################
    //####################################################################################
    //####################################################################################
    //EC2  User Data

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

        #Make a directory to mount the containers volumes in it.
        sudo mkdir ${var.home-directory}volumes/

        #****The sub-project of saving images in the EBS volume will be postponed for now. This command is unused.
        #Make a directory to mount the docker images volumes in it.
        #****sudo mkdir ${var.home-directory}docker_images/

        echo "Check if volume is attached..."
        # Wait for the containers volume to be available
        while [ ! -e /dev/xvdf ]; do
          echo "Waiting for /dev/xvdf to be available..."
          sleep 5
        done
        echo "Volume is attached."

        #****The sub-project of saving images in the EBS volume will be postponed for now. This command is unused.
        # Wait for the docker images volume to be available
        #****while [ ! -e /dev/xvdd ]; do
        #****  echo "Waiting for /dev/xvdd to be available..."
        #****  sleep 5
        #****done

        #format the attached EBS volume only if variable "container_volume_initialize" is set to true
        ${!var.container_volume_initialize ? "#": ""} sudo mkfs -t ext4 /dev/xvdf

        #****The sub-project of saving images in the EBS volume will be postponed for now. This command is unused.
        #format the images_volume only if variable "refresh_docker_images" is set to true
        #**** $ { !var .  refresh_docker_images ? "#": ""} sudo mkfs -t ext4 /dev/xvdd

        # mount the EBS volume for containers persistance into the EC2 folder /home/ec2-user/volumes/
        sudo mount /dev/xvdf ${var.home-directory}volumes/

        #The sub-project of saving images in the EBS volume will be postponed for now. This command is unused.
        # mount the EBS volume for docker images into the EC2 folder /home/ec2-user/docker_images/
        #****sudo mount /dev/xvdd ${var.home-directory}docker_images/


        #The sub-project of saving images in the EBS volume will be postponed for now. These commands are unused.
        # Swap the docker images volume to /var/lib/docker
        #****systemctl stop docker
        #****systemctl enable docker
        #If the variable "container_volume_initialize" is set to true, then we need to move the docker images to volume.
        #**** $ { !var.refresh_docker_images ? "#": ""} sudo mv /var/lib/docker ${var.home-directory}docker_images/

        #If "container_volume_initialize" the folder will be deleted by previous command. but if not, we should delete it.
        #**** $ { var.refresh_docker_images ? "#": ""} rm -rf /var/lib/docker
        #****ln -s ${var.home-directory}docker_images/ /var/lib/docker
        #****systemctl start docker



        #Copy the file hosts to /etc/hosts. This requires SUDO access therefore could not be done via provisioning.
        sudo cp ${var.home-directory}hosts /etc/hosts

        #It is not a must to create the folders for mouting into container. Docker make the folders if they do not exist.
        #This musr run only if it is the initialize mode: only if the variable "volume-initialize" is set to true
        #Follwing volumes are needed
            # mariadb
            # james
            # joomla
            # crm
        ${!var.container_volume_initialize ? "#": ""} sudo mkdir ${var.home-directory}volumes/${var.db_volume}/
        ${!var.container_volume_initialize ? "#": ""} sudo mkdir ${var.home-directory}volumes/${var.crm_volume}/
        ${!var.container_volume_initialize ? "#": ""} sudo mkdir ${var.home-directory}volumes/${var.joomla_volume}/


        #copying the .htaccess and configuration.php file to the joomla volume. Only if it is server initialization mode.
        ${!var.container_volume_initialize ? "#": ""} sudo cp ${var.home-directory}.htaccess ${var.home-directory}/volumes/${var.joomla_volume}/.htaccess

        #To avoid an error, first one should make the folder for database persistant data before give the ownership to mysql.
        #give the ownership fo the docker volume for database to mysql. MySQL needs it to write data into the volume.
        sudo chown -R 999:999 ${var.home-directory}volumes/${var.db_volume}/

        fix ownership of the CRM volume
        sudo chown -R 999:999 ${var.home-directory}volumes/${var.crm_volume}/

        #Run the containers
        #It is important to run this command with (-d) to detach, otherwise the rest of the initializers will not execute.
        docker-compose -f ${var.home-directory}compose.yml up -d

        #Inform the user that you are waiting for the containers to be up and running
        #The following initializers will be executed only if the server is being initialized.
        ${!var.container_volume_initialize ? "#": ""}echo "Waiting for the containers to be up and running..."
        ${!var.container_volume_initialize ? "#": ""}sleep 60

        # Changing the ownership of the james initializers file and execing it.
        ${!var.container_volume_initialize ? "#": ""}sudo chmod +x ${var.home-directory}james_initialize.sh
        ${!var.container_volume_initialize ? "#": ""}sudo bash ${var.home-directory}james_initialize.sh

        ${!var.container_volume_initialize ? "#": ""}echo "Waiting another 20 seconds for CRM to load completely."
        ${!var.container_volume_initialize ? "#": ""}sleep 30

        # Changing the ownership of the database initializers file and execing it.
        ${!var.container_volume_initialize ? "#": ""}sudo chmod +x ${var.home-directory}crm_initialize.sh
        ${!var.container_volume_initialize ? "#": ""}sudo bash ${var.home-directory}crm_initialize.sh

        # Add the SSL certificates to the trusted sources of Java, in our Rest API container and restarting it.
        sudo docker exec ${var.rest-api-container-name} bash -c "keytool -import -trustcacerts -alias myserver -file /certificates/fullchain.pem -cacerts -storepass changeit -noprompt"
        sudo docker restart ${var.rest-api-container-name}

        echo "Thusia server setup cmpleted."
    EOF
}

resource "aws_volume_attachment" "Thusia_data" {
  device_name = "/dev/sdf"  # The device name you want to use (e.g., /dev/sdf)
  volume_id   = var.containers_volume_id  # Replace with your EBS volume ID
  instance_id = aws_instance.my_instance.id
  # Ensure that the attachment waits for the instance to be ready.
  depends_on = [aws_instance.my_instance]
}

#****resource "aws_volume_attachment" "Docker_images" {
#****    device_name = "/dev/sdd"  # The device name you want to use (e.g., /dev/sdf)
#****    volume_id   = var.docker_images_volume_id  # Replace with your EBS volume ID
#****    instance_id = aws_instance.my_instance.id
#****    # Ensure that the attachment waits for the instance to be ready.
#****    depends_on = [aws_instance.my_instance]
#****}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.my_instance.id
  allocation_id = var.eip_association_id
}