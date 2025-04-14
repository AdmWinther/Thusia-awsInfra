variable "crm-docker-image" {}

resource "local_file" "suitecrm_docker_image" {
  filename = "Dockerfile"
  content  = <<EOF
    # Start from the Bitnami SuiteCRM base image
    FROM ${var.crm-docker-image}

    # Switch to the root user to install packages
    USER root

    # Set the working directory to SuiteCRM folder
    WORKDIR /bitnami/suitecrm

    # Install Composer
    RUN composer install

    # Run Composer install and generate the keys
    # This will execute when the container starts
    CMD ["sh", "-c", "\
      cd /bitnami/suitecrm/public/legacy/Api/V8/OAuth2 && \
      openssl genrsa -out private.key 2048 && \
      openssl rsa -in private.key -pubout -out public.key && \
      chmod 600 private.key public.key && \
      chown daemon:daemon p*.key \
"]
EOF
}