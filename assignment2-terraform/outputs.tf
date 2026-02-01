output "load_balancer_dns" {
  value = "http://${aws_lb.hr_alb.dns_name}"
}

output "database_private_ip" {
  value = aws_instance.hr_database.private_ip
}