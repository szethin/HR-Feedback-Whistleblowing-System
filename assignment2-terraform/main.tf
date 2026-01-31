provider "aws" {
  region = "us-east-1" # Change if your sandbox is in a different region (e.g., us-west-2)
}

# 1. VPC (Virtual Private Cloud) - The "House"
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "HR-System-VPC" }
}

# 2. Internet Gateway - The "Front Door"
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "HR-IGW" }
}

# 3. Availability Zones Data Source
data "aws_availability_zones" "available" {
  state = "available"
}