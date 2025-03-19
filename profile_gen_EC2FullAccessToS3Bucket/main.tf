# Create an IAM profile for EC2 instance with S3 access
# 1st. we need to make the role.
resource "aws_iam_role" "ec2_role" {
  name               = "role_ec2_full_access_s3"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

}

# 2nd. we need to make the policy document. The policy document defines the entities
# that the role can be assigned to. We want to assign this role to EC2
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 3rd. we define the permissions in the policy. Those that take the role
# can have full access to all S3 buckets. So we create IAM Policy
# to give full access to S3 to the EC2 that assume this role.
resource "aws_iam_policy" "s3_full_access" {
  name        = "policy_s3_full_access"
  description = "A policy that allows full access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}

# 4th. at the end, we attach the policy to the role.
# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  policy_arn = aws_iam_policy.s3_full_access.arn
  role       = aws_iam_role.ec2_role.name
}

# 5th, EC2 cannot assume role, because it is not human. it instead can assume
# profile. so we make a profile and assign the role to the profile. the profile
# I guess can have more than one role.
# Create an IAM Instance Profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
   role = aws_iam_role.ec2_role.name
}