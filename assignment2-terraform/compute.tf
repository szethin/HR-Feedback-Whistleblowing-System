# User Data Script (Runs on server startup to install your app)
variable "user_data_script" {
  default = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              pip3 install flask pyodbc
              
              # Clone your code
              cd /home/ec2-user
              git clone https://github.com/szethin/HR-Feedback-Whistleblowing-System.git app
              cd app
              
              # Start the app (Simple background run)
              # Assumes your main file is app.py and runs on port 5000
              nohup python3 app.py > app.log 2>&1 &
              EOF
}

# EC2 Launch Template
resource "aws_launch_template" "app_lt" {
  name_prefix   = "hr-app-lt"
  image_id      = "ami-0c614dee691cbbf37" # Amazon Linux 2023 (US-East-1)
  instance_type = "t2.micro"
  
  network_interfaces {
    security_groups = [aws_security_group.app_sg.id]
    associate_public_ip_address = false # Private Subnet
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(var.user_data_script)
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.tg.arn]
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "hr-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "hr-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/" # Make sure your app has a route for '/'
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}