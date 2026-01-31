# Create a Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "hr_ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Allow EC2 to access S3 (Least Privilege)
resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access_policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["s3:GetObject", "s3:ListBucket"]
      Effect = "Allow"
      Resource = "*"
    }]
  })
}

# Instance Profile (Passes the role to the EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "hr_ec2_profile"
  role = aws_iam_role.ec2_role.name
}