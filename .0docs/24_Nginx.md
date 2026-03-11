# Nginx Reverse Proxy Configuration

## Purpose

Nginx serves as a reverse proxy and SSL termination point.


---

## Subdomain Routing

www.awin.dk → Joomla
crm.awin.dk → SuiteCRM
api.awin.dk → REST API

Each subdomain has its own server block.

---

## SSL Handling

Certificates:
- fullchain.pem
- privkey.pem

Best practice:
ssl_certificate     fullchain.pem;
ssl_certificate_key privkey.pem;

SSL termination happens at Nginx.
Containers communicate internally over HTTP.

### SSL Certificate Generation

The SSL certificates are generated using the Terraform module located at `___ShredModules___/file_gen_SSL_Agent`. This module creates a script that can be executed on the server to obtain and renew SSL certificates from a certificate authority.

---

## Proxy Headers

The following headers are forwarded:

- Host
- X-Real-IP
- X-Forwarded-For
- X-Forwarded-Proto

This ensures correct application-level HTTPS detection.