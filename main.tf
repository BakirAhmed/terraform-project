# ============================================
# 1. VPC
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ============================================
# 2. Subnets (2 publics, 2 privés)
# ============================================
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-priv-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-priv-subnet-2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-subnet-1"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-subnet-2"
  }
}

# ============================================
# 3. Internet Gateway
# ============================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ============================================
# 4. Route Tables
# ============================================
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-RT"
  }
}

resource "aws_route_table" "private_RT" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-RT"
  }
}

# ============================================
# 5. NAT Gateway
# ============================================
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet4.id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

# Route NAT pour les subnets privés
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_RT.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# ============================================
# 6. Associations des subnets
# ============================================
resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "subnet2_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private_RT.id
}

resource "aws_route_table_association" "subnet3_association" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "subnet4_association" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.public_RT.id
}

# ============================================
# 7. Security Groups
# ============================================
resource "aws_security_group" "HTTP_SG" {
  name        = "${var.project_name}-sg-http"
  description = "HTTP and SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "${var.project_name}-HTTP-SG"
  }
}

resource "aws_security_group" "jumper_SG" {
  name        = "${var.project_name}-SG-jumper"
  description = "Bastion host SSH access"
  vpc_id      = aws_vpc.main.id

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
    Name = "${var.project_name}-SG-jumper"
  }
}

# ============================================
# 8. Bastion Host
# ============================================
resource "aws_instance" "jumper_instance" {
  ami                    = var.ami_bastion
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet3.id
  vpc_security_group_ids = [aws_security_group.jumper_SG.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# ============================================
# 9. S3 Bucket
# ============================================
resource "aws_s3_bucket" "ahmed_s3" {
  bucket        = "ahmed-s3-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-s3-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
} # Génère une chaîne aléatoire

# ============================================
# 10. IAM Role and Policy
# ============================================
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"  # date de la dernière version majeure du langage des politiques IAM
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

resource "aws_iam_policy" "s3_policy" {
  name = "${var.project_name}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.ahmed_s3.arn,
          "${aws_s3_bucket.ahmed_s3.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ============================================
# 11. ALB (Load Balancer)
# ============================================
resource "aws_lb" "test" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.HTTP_SG.id]
  subnets                    = [aws_subnet.subnet3.id, aws_subnet.subnet4.id]
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Create Target Group 
resource "aws_lb_target_group" "test" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2     # Nb de succès pour dire "OK" 
    unhealthy_threshold = 2     # Nb d'échecs pour dire "HS"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Create Listener for ALB 
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

# ============================================
# 12. Auto Scaling Group
# ============================================
resource "aws_launch_configuration" "app" {
  name_prefix   = "${var.project_name}-launch-configuration"
  image_id      = var.ami_app
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.HTTP_SG.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    echo "Hello, World from ASG, $(hostname -f)" > /home/ec2-user/index.html
    cd /home/ec2-user
    nohup python3 -m http.server 80 &
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                 = "${var.project_name}-ASG"
  launch_configuration = aws_launch_configuration.app.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  target_group_arns    = [aws_lb_target_group.test.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-instance"
    propagate_at_launch = true
  }
}