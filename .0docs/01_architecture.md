# Architecture Documentation

## High-Level Overview

The Thusia infrastructure is deployed on AWS and designed using Infrastructure as Code principles.
The system runs a containerized multi-service architecture on a single EC2 instance, with persistent storage backed by EBS.

The environment is provisioned using Terraform and services are orchestrated with Docker Compose.

---

## Logical Architecture

Client Traffic Flow:

1. Client request (HTTPS)
2. DNS resolution (Domain provider)
3. EC2 Instance
4. Nginx Reverse Proxy (SSL termination)
5. Internal Docker network
6. Target container (SuiteCRM, Joomla, REST API)

---

## Infrastructure Components

### Compute
- AWS EC2 instance
- Docker runtime environment

### Storage
- AWS EBS volume
- Mounted and attached during instance provisioning
- Used for persistent application data

### Networking
- Security Groups restricting inbound traffic
- Internal Docker bridge network
- Reverse proxy routing via Nginx

---

## Container Architecture

Services:

- Nginx (reverse proxy)
- SuiteCRM
- Joomla
- REST API service
- MySQL database

Each container runs in isolation but shares a common Docker network.

---

## Security Model

- HTTPS enforced via Nginx
- SSL certificates managed with Let's Encrypt
- Sensitive credentials stored via environment variables
- Persistent volume permissions managed carefully
- No direct public exposure of database container