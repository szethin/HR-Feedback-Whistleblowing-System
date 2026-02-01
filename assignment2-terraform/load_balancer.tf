# 1. Target Group
resource "aws_lb_target_group" "hr_tg" {
  name     = "HR-Targets"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/"
  }
}

# Attach App Server to Target Group
resource "aws_lb_target_group_attachment" "hr_attach" {
  target_group_arn = aws_lb_target_group.hr_tg.arn
  target_id        = aws_instance.hr_app_server.id
  port             = 5000
}

# 2. Application Load Balancer
resource "aws_lb" "hr_alb" {
  name               = "HR-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# 3. Listener (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.hr_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hr_tg.arn
  }
}