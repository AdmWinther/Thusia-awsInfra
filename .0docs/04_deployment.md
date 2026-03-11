# Deployment Documentation

## Provisioning Phase

1. Run terraform init
2. Run terraform plan
3. Run terraform apply

Terraform provisions AWS infrastructure.

---

## Bootstrapping Phase

After EC2 is ready:

- Docker is installed
- Docker Compose is configured
- Required directories are created
- EBS volume is mounted

---

## Application Deployment

Docker Compose launches:

- Nginx reverse proxy
- SuiteCRM
- Joomla
- REST API
- MySQL

---

## SSL Configuration

SSL certificates are mounted into the Nginx container.

Nginx handles:
- HTTP to HTTPS redirection
- SSL termination
- Reverse proxy routing

---

## Persistence Strategy

Application data is stored on EBS-backed directories to ensure data survives container restarts.