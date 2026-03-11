# EBS volume for Persistent data Storage Documentation

## EBS Volume

An AWS EBS volume provides persistent storage. To store the data of the EC2 and have the possebility to move it to another server, or keep the data even after the server is terminated, an EC2 EBS volume is needed.
The EBS volume must be made in the AWS account, in the same region and availability zone as the server.
It is recommended to first make the EBS volume and them make the server in the same region and availability zone as of the EBS volume.


---

## Persistence Strategy
The EBS volume will be mounted in the server, under "{home_directory}/volume", in which "{home_directory}" is set in the config file terraform.tfvars.
For example, while using "ami-08b5b3a93ed654d19" as "ec2-ami", the OS would be AWS Linux and {home-directory} can be st as "/home/ec2-user/", therefore, the EBS volume will be mounted in "/home/ec2-user/volume/".
The data for Docker Containers will be stored in EBS volume. For each container that needs to have persistent data, there would be a folder under "{home_directory}/volume"

The EBS volume is Attached via Terraform:
aws_volume_attachment