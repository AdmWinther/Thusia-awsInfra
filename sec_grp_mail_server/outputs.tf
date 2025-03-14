output "aws_security_group" {
  description = "the entire security group"
  value       = aws_security_group.mail_server
}

output "sec_grp_name" {
  description = "the name of the security group"
  value       = aws_security_group.mail_server.name
}
