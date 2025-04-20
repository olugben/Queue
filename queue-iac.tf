# Define provider (us-west-2)
provider "aws" {
  region = "us-west-2"
}

# Random name generator for unique resource names
resource "random_pet" "name_suffix" {
  length    = 2
  separator = "-"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc-${random_pet.name_suffix.id}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw-${random_pet.name_suffix.id}"
  }
}

# Create public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a-${random_pet.name_suffix.id}"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b-${random_pet.name_suffix.id}"
  }
}

# Create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-${random_pet.name_suffix.id}"
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${random_pet.name_suffix.id}"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-${random_pet.name_suffix.id}"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${random_pet.name_suffix.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${random_pet.name_suffix.id}"
  role = aws_iam_role.ec2_role.name
}

# Launch Template
resource "aws_launch_template" "app_template" {
  name          = "app-template-${random_pet.name_suffix.id}"
  image_id      = "ami-03f65b8614a860c29" # Ubuntu 20.04 in us-west-2
  instance_type = "t2.micro"
  key_name      = "my-terraform-key"    # Replace with your key pair name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
# Strict error handling
set -euo pipefail
# Log everything
exec > >(tee /var/log/user-data.log) 2>&1

# Wait for cloud-init
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done

echo "=== Starting deployment ==="

# 1. System setup
echo "[1/6] Updating system..."
sudo apt-get update -y
sudo apt-get install -y git curl docker.io

# 2. Docker setup
echo "[2/6] Configuring Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# 3. Docker Compose install
echo "[3/6] Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-Linux-x86_64" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 4. Clean deployment
echo "[4/6] Deploying application..."
sudo rm -rf /home/ubuntu/DRFQ
git clone https://github.com/olugben/Queue.git /home/ubuntu/DRFQ

# 5. Start containers
echo "[5/6] Starting containers..."
cd /home/ubuntu/DRFQ
sudo docker compose down || true
sudo docker compose up -d --build

# 6. Final setup
echo "[6/6] Finalizing..."
sudo mkdir -p /var/www/html
echo "Deployed at $(date)" | sudo tee /var/www/html/healthcheck.html >/dev/null

echo "=== Deployment completed successfully ==="
EOF
)
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-instance-${random_pet.name_suffix.id}"
    }
  }
}

# Target Group
resource "aws_lb_target_group" "app_target_group" {
  name        = "tg-${random_pet.name_suffix.id}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/api/public-health-check"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "app-target-group"
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb-${random_pet.name_suffix.id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "app-load-balancer"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "asg-${random_pet.name_suffix.id}"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  health_check_type   = "ELB"
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_target_group.arn]

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

# Output ALB DNS name
output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}