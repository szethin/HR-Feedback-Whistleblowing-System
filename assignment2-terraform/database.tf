resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id]
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  engine                 = "sqlserver-ex" # SQL Server Express (Free Tier eligible)
  engine_version         = "15.00.4043.16.v1" # Check valid version if error occurs
  instance_class         = "db.t3.micro"
  identifier             = "hr-db"
  username               = "adminuser"
  password               = "SuperSecurePass123!" # In real life, use Secrets Manager!
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  storage_encrypted      = true # Requirement: Encrypted Storage
  multi_az               = false # Cost saving for Sandbox. Set true for report.
}