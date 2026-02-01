# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "hr_database" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.small" # Required for SQL Server
  subnet_id     = aws_subnet.private_db_a.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  iam_instance_profile   = "LabInstanceProfile"

  tags = { Name = "HR-Database" }

  # Install Docker & SQL Server automatically
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              docker run -e "ACCEPT_EULA=Y" \
                 -e "MSSQL_SA_PASSWORD=SuperSecurePass123!" \
                 -p 1433:1433 \
                 --name sql_server \
                 --restart always \
                 -d mcr.microsoft.com/mssql/server:2022-latest
              EOF
}