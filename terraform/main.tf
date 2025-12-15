#############################################
# DEFAULT VPC & SUBNET DISCOVERY
#############################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_caller_identity" "current" {}

#############################################
# ECR REPOSITORY  (MUST BE IMPORTED FIRST)
#############################################

#resource "aws_ecr_repository" "strapi" {
#  name = var.docker_repo   # Example: sandeep-strapi

#  image_scanning_configuration {
#    scan_on_push = true
#  }
#}

#############################################
# SECURITY GROUP FOR EC2
#############################################

resource "aws_security_group" "ec2_sg" {
  name        = "sandeep-ec2-sg"
  description = "Allow SSH and Strapi"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow Strapi"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
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
}

#############################################
# SECURITY GROUP FOR RDS
#############################################

resource "aws_security_group" "rds_sg" {
  name        = "sandeep-rds-sg"
  description = "Allow EC2 to Postgres"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow Postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# DB SUBNET GROUP
#############################################

resource "aws_db_subnet_group" "default" {
  name       = "sandeep-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

#############################################
# RDS POSTGRES INSTANCE
#############################################

resource "aws_db_instance" "postgres" {
  identifier              = "sandeep-postgres-db"
  engine                  = "postgres"
  engine_version          = "15.15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  skip_final_snapshot     = true
  publicly_accessible     = false
}

#############################################
# EC2 INSTANCE (Ubuntu)
#############################################

resource "aws_instance" "ubuntu" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 LTS
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name

user_data = <<-EOF
#!/bin/bash

apt update -y
apt install -y docker.io awscli
systemctl enable docker
systemctl start docker

# Configure AWS credentials
mkdir -p /root/.aws

cat <<AWSCFG >/root/.aws/credentials
[default]
aws_access_key_id=${var.aws_access_key_id}
aws_secret_access_key=${var.aws_secret_access_key}
region=${var.aws_region}
AWSCFG

cat <<AWSCONF >/root/.aws/config
[default]
region=${var.aws_region}
output=json
AWSCONF

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="${var.aws_region}"

# Build ECR repo URL
REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${var.docker_repo}"
IMAGE="$REPO:${var.image_tag}"

# Login to ECR
aws ecr get-login-password --region $REGION | docker login \
  --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull Docker image
docker pull $IMAGE

# Restart container
docker stop strapi || true
docker rm strapi || true

# Run Strapi container
docker run -d --name strapi -p 1337:1337 \
  -e APP_KEYS="ba93e7f9a88b4e648aa9e2d1d8b3c7ff,8c44e9a0dc4f452da9b2b6e8a09bfc3d,fc8c319a89d64c95b8e6f4420f2e7da4,b7b3a4e26bb94a09a5e6288d2f2e0d19" \
  -e ADMIN_JWT_SECRET="8fa2a7bcb6a6400a85e3a5b87d23b8c9" \
  -e API_TOKEN_SALT="OTM4YzQ3ZjZlM2EzN2Q2Ng==" \
  -e JWT_SECRET="JHNKA9NVfw0Oi2VsIA06Tw==" \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=${aws_db_instance.postgres.address} \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=postgres \
  -e DATABASE_USERNAME=${var.db_username} \
  -e DATABASE_PASSWORD="${var.db_password}" \
  $IMAGE

EOF




  tags = {
    Name = "sandeep-ec2"
  }
}

#############################################
# OUTPUTS
#############################################

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

#output "ecr_repo_url" {
#  value = aws_ecr_repository.strapi.repository_url
#}