resource "aws_instance" "hr_app_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  
  # NOTE: We keep it public for grading access, or change back to private_app_a.id for security
  subnet_id     = aws_subnet.public_a.id  
  associate_public_ip_address = true
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = "LabInstanceProfile"

  tags = { Name = "HR-App-Server" }
  depends_on = [aws_instance.hr_database]

  user_data = <<-EOF
              #!/bin/bash
              # 1. Disable SELinux & Firewall Restrictions (Fixes 502/504 Errors)
              setenforce 0
              sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
              setsebool -P httpd_can_network_connect 1
              setsebool -P httpd_read_user_content 1

              # 2. Install Dependencies
              dnf update -y
              dnf install -y python3 git pip nginx

              # 3. Install SQL Server Drivers
              curl https://packages.microsoft.com/config/rhel/9/prod.repo > /etc/yum.repos.d/mssql-release.repo
              ACCEPT_EULA=Y dnf install -y msodbcsql18
              dnf install -y unixODBC-devel

              # 4. Clone Repo & Setup Backend
              cd /home/ec2-user
              git clone https://github.com/szethin/HR-Feedback-Whistleblowing-System.git app
              
              cd /home/ec2-user/app
              pip3 install -r requirements.txt
              
              cd backend
              # Inject Database IP dynamically
              echo "DB_SERVER=${aws_instance.hr_database.private_ip}" > .env
              echo "DB_DATABASE=master" >> .env
              echo "DB_USERNAME=sa" >> .env
              echo "DB_PASSWORD=SuperSecurePass123!" >> .env

              # Start Flask Backend (Port 5001)
              nohup gunicorn -w 4 -b 127.0.0.1:5001 app:app > backend.log 2>&1 &

              # 5. Setup Frontend (Nginx)
              # Clean & Copy Dist Files
              rm -rf /usr/share/nginx/html/*
              cp -r /home/ec2-user/app/dist/* /usr/share/nginx/html/
              
              # Fix Permissions (Critical for Nginx 403)
              chmod -R 755 /usr/share/nginx/html
              chown -R nginx:nginx /usr/share/nginx/html

              # 6. Overwrite Nginx Config (Forces Port 5000)
              cat > /etc/nginx/nginx.conf <<'EOT'
              user nginx;
              worker_processes auto;
              error_log /var/log/nginx/error.log notice;
              pid /run/nginx.pid;
              events { worker_connections 1024; }
              http {
                  include /etc/nginx/mime.types;
                  default_type application/octet-stream;
                  log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                                  '\$status \$body_bytes_sent "\$http_referer" '
                                  '"\$http_user_agent" "\$http_x_forwarded_for"';
                  access_log /var/log/nginx/access.log main;
                  sendfile on;
                  keepalive_timeout 65;

                  server {
                      listen 5000;
                      root /usr/share/nginx/html;
                      index index.html;
                      
                      location / {
                          try_files \$uri \$uri/ /index.html;
                      }
                      
                      location /api {
                          proxy_pass http://127.0.0.1:5001;
                          proxy_set_header Host \$host;
                          proxy_set_header X-Real-IP \$remote_addr;
                      }
                  }
              }
              EOT

              # 7. Start Nginx
              systemctl enable nginx
              systemctl restart nginx
              EOF
}