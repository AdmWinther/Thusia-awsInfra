output "aws_iam_instance_profile" {
  description = "The entire aws instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile
}

output "ec2_full_access_to_ses_profile_name" {
  description = "The name of the  aws instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}
