output "aws_security_group" {
  description = "the entire security group"
  value       = aws_security_group.http_https_ssh_database
}

output "sec_grp_name" {
  description = "the name of the security group"
  value       = aws_security_group.http_https_ssh_database.name
}
