# Thusia – AWS Infrastructure & Containerized Web Platform

## Overview

Thusia is a fully containerized web infrastructure deployed on AWS using Terraform.
The project provisions cloud infrastructure, configures secure networking, attaches persistent storage, and deploys multiple services behind a reverse proxy (Nginx).
The communications between the clients and the server is secured with SSL termination.

The system hosts:

- SuiteCRM (CRM platform)
- Joomla (CMS website)
- REST API service
- Nginx reverse proxy with Let's Encrypt SSL
- Dockerized service architecture
- Persistent EBS-backed storage

This project demonstrates infrastructure automation, container orchestration, reverse proxy configuration, secure certificate management, and production-grade deployment patterns.

---

## Architecture Overview
Client Browser
↓
The domain provider DNS server
↓
AWS EC2 Instance
↓
Nginx Reverse Proxy (SSL Termination)
↓
Docker Compose Network
├── SuiteCRM Container
├── Joomla Container
└── REST API Container

(the database does not have an externally exposed web interface.)

AWS EBS Volume is used for the sake of data Persistence.

---

## Technologies Used

- Terraform (Infrastructure as Code)
- AWS EC2
- AWS EBS
- AWS Security Groups
- Docker & Docker Compose
- Nginx Reverse Proxy
- Let's Encrypt SSL
- MariaDB (SQL based DB)
- Linux (Amazon Linux / Ubuntu)
- Bash scripting (for automation of various processes)

---

## Key Infrastructure Features

- Automated EC2 provisioning via Terraform
- EBS volume attachment and persistent mounting
- Reverse proxy routing multiple subdomains
- HTTPS enforcement with SSL certificates
- Docker-based service isolation
- Secure handling of OAuth keys for SuiteCRM
- Automatic container networking
- Separation of infrastructure and application layers

---

## Deployment Flow

1. Terraform provisions:
   - EC2 instance
   - Security Groups
   - EBS volume
   - Volume attachment
   - Generating config files (for example Docker Compose .YML file, Config file for NGINX, etc.)

2. EC2 bootstraps Docker environment.

3. Docker Compose deploys:
   - MariaDB
   - Apache James Mail Server
   - SuiteCRM
   - Joomla
   - REST API
   - Nginx reverse proxy

Note: All of the containers, except REST API and SuiteCRM are using official docker images.
For REST API and SuiteCRM container, custom made containers are used.
For more information about the custom containers, please visit the following GitHub repositories:
SuiteCRM: https://github.com/AdmWinther/DockerImage-SuiteCRM
Rest API: https://github.com/AdmWinther/Thusia_Rest_API

4. Nginx handles:
   - SSL termination
   - HTTP → HTTPS redirection
   - Sending requests based on the requested subdomain to corresponding container
        - `www.awin.dk` → Joomla
        - `crm.awin.dk` → SuiteCRM
        - `api.awin.dk` → REST API


## Infrastructure Philosophy
This project focuses on:
- Infrastructure reproducibility
- Security-first configuration (Zero trust approach)
- Proper separation of concerns (Micro Service Architecture)
- Persistent storage design
- To renew SSL certificates, file_gen_SSL_Agent module is developed. Module generates a script file that can be executed on the server to renew the SSL certificates.

---

## Future Improvements

- CI/CD integration
- Terraform modularization
- CloudWatch logging integration
- Auto-scaling infrastructure (Kubernetes)

---

## Author
Adam Winther
Backend & Infrastructure developer