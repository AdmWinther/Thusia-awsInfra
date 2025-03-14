variable "my_vpc_id" {
  description = "AWS account VPC_ID"
  type        = string
}

resource "aws_security_group" "mail_server" {
  name        = "smtp-imap-pop3-httprestapi-sg"
  description = "Allow SMTP, IMAP, POP3, and HTTP REST API traffic"
  vpc_id      = var.my_vpc_id

  # SMTP (Simple Mail Transfer Protocol) :
  # SMTP - sending email
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SMTP - submission for email clients that will submit messages for delivery
  ingress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IMAP (Internet Message Access Protocol) :
  # IMAP - standard IMAP connections
  ingress {
    from_port   = 143
    to_port     = 143
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # IMAP - IMAP over SSL/TLS
  ingress {
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # POP3 (Post Office Protocol) :
  # POP3 - standard POP3 connections
  ingress {
    from_port   = 110
    to_port     = 110
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # POP3 - POP3 over SSL/TLS
  ingress {
    from_port   = 995
    to_port     = 995
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (for REST APIs) :
  # HTTP - default port for HTTP services, including REST
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
