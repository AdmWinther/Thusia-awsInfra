# Terraform Infrastructure Documentation

## Purpose

Terraform is used to provision and manage AWS infrastructure components in a reproducible and version-controlled manner.

---

## Resources Provisioned

- EC2 Instance
- Security Groups
- Volume Attachment
Note: To achieve persistent data, an EBS volume is made and will be attached to the EC2.
If the flag "container_volume_initialize" in terraform.tfvars is set to "true" the EBS will be formatted, otherwise it will keep the data from previous deployment of the server.

---

## Volume Attachment Strategy

The EBS volume is attached using:

aws_volume_attachment

Although the device name is specified as /dev/sdf, AWS exposes it to Linux as /dev/xvdf.
This is expected behavior due to AWS virtualization mapping.

A wait loop ensures the device exists before mounting:

while [ ! -e /dev/xvdf ]; do
  sleep 5
done

---

## terraform.tfvars

The terraform.tfvars file contains environment-specific variables such as:

- my_vpc_id: The vcp id of the AWS account.
- ec2-ami: The ami for the EC2. Depends on the ami, the operation system will change. The recommended OS is AWS Linux.
- package-installer: Based on OS, one must set the packet installer, yum or apt-get. for AWS linux, you can set it to yum.
- home-directory: The home directory is where the files will be stored, for AWS linux, set it to /home/ec2-user/.
- container_volume_initialize: will be set to true, if the server must start from scratch.
- containers_volume_id: The id of the EBS volume for persistent data.
- domain_name: the application domain.
- eip_association_id: The ID of elastic IP set to the server. To avoid setting up the server DNS entries everytime the server resets, an elastic IP is needed.
- my_ip_address: The IP of the server. AWS elastic IP.