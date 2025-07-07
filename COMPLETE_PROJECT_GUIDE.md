# Complete Guide: Deploy PHP Rentzone Application on AWS EKS

## Table of Contents
1. [Project Overview](#project-overview)
2. [Prerequisites & Tools Setup](#prerequisites--tools-setup)
3. [AWS Account Setup](#aws-account-setup)
4. [Local Development Environment](#local-development-environment)
5. [Project Structure](#project-structure)
6. [Infrastructure Setup with Terraform](#infrastructure-setup-with-terraform)
7. [Docker Configuration](#docker-configuration)
8. [Kubernetes Configuration](#kubernetes-configuration)
9. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
10. [Database Setup](#database-setup)
11. [Deployment Process](#deployment-process)
12. [Testing & Verification](#testing--verification)
13. [Troubleshooting](#troubleshooting)
14. [Cost Management](#cost-management)

---

## Project Overview

### What We're Building
- **Application**: PHP-based Rentzone property management system
- **Infrastructure**: AWS EKS (Kubernetes) cluster
- **Database**: AWS RDS MySQL
- **CI/CD**: AWS CodeBuild for automated deployments
- **Container Registry**: AWS ECR
- **Load Balancing**: AWS Application Load Balancer

### Key Technologies Explained
- **EKS (Elastic Kubernetes Service)**: Managed Kubernetes service on AWS
- **Docker**: Containerization platform to package applications
- **Terraform**: Infrastructure as Code tool
- **Kubernetes**: Container orchestration platform
- **RDS**: Managed database service

---

## Prerequisites & Tools Setup

### 1. Create AWS Account
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the registration process
4. **Important**: Set up billing alerts to monitor costs

### 2. Install Required Tools

#### A. Install AWS CLI
**Windows:**
```bash
# Download and install AWS CLI from: https://aws.amazon.com/cli/
# Or use PowerShell:
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Verify Installation:**
```bash
aws --version
```

#### B. Install Terraform
**Windows:**
1. Download from [terraform.io](https://www.terraform.io/downloads)
2. Extract to a folder (e.g., `C:\terraform`)
3. Add to PATH environment variable

**Verify Installation:**
```bash
terraform --version
```

#### C. Install kubectl
```bash
# Windows (using curl)
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
# Move kubectl.exe to a directory in your PATH
```

**Verify Installation:**
```bash
kubectl version --client
```

#### D. Install Git
Download and install from [git-scm.com](https://git-scm.com/)

#### E. Install Docker Desktop
Download and install from [docker.com](https://www.docker.com/products/docker-desktop/)

### 3. Install Code Editor
- **Recommended**: Visual Studio Code with extensions:
  - Terraform
  - Kubernetes
  - Docker
  - YAML

---

## AWS Account Setup

### 1. Create IAM User
```bash
# Login to AWS Console → IAM → Users → Create User
# Username: terraform-user
# Attach policies:
# - AdministratorAccess (for learning - use more restrictive in production)
```

### 2. Configure AWS CLI
```bash
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: eu-west-1
# Default output format: json
```

### 3. Test AWS Connection
```bash
aws sts get-caller-identity
```

---

## Local Development Environment

### 1. Create Project Directory
```bash
mkdir ARM1-EKS
cd ARM1-EKS
```

### 2. Initialize Git Repository
```bash
git init
git remote add origin https://github.com/YOUR_USERNAME/ARM1-EKS.git
```

### 3. Create Basic Project Structure
```
ARM1-EKS/
├── docker/
├── k8s/
├── terraform files
└── application files
```

---

## Project Structure

### Complete File Structure
```
ARM1-EKS/
├── docker/
│   ├── Dockerfile
│   ├── apache-config.conf
│   ├── docker-entrypoint.sh
│   ├── .env.template
│   ├── index.php
│   └── rentzone.zip
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── secrets.yaml
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
├── vpc.tf
├── security-groups.tf
├── eks-cluster.tf
├── rds.tf
├── ecr.tf
├── codebuild.tf
├── iam-roles.tf
├── natgateway.tf
├── buildspec-docker.yml
├── buildspec-terraform.yml
├── terraform.tfvars
├── rentzone.zip
├── rentzone-db.sql
└── README.md
```

---

## Infrastructure Setup with Terraform

### Step 1: Create Terraform Backend Configuration

**File: `backend.tf`**
```hcl
terraform {
  backend "s3" {
    bucket = "arm1-terraform-state-bucket-unique-name"
    key    = "arm1-eks/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

**What this does**: Stores Terraform state in S3 for team collaboration and state locking.

### Step 2: Configure Providers

**File: `providers.tf`**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### Step 3: Define Variables

**File: `variables.tf`**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "arm1-eks-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

### Step 4: Set Variable Values

**File: `terraform.tfvars`**
```hcl
aws_region   = "eu-west-1"
cluster_name = "arm1-eks-cluster"
environment  = "production"
db_username  = "admin"
db_password  = "YourSecurePassword123!"
```

### Step 5: Create VPC and Networking

**File: `main.tf`**
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

**What this does**: Creates a VPC with public and private subnets across multiple availability zones for high availability.

### Step 6: Create NAT Gateway

**File: `natgateway.tf`**
```hcl
# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

**What this does**: Creates NAT gateways for private subnets to access the internet securely.

### Step 7: Create Security Groups

**File: `security-groups.tf`**
```hcl
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-cluster-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-node-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All traffic from cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "All traffic from cluster security group"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}
```

**What this does**: Creates security groups to control network traffic between EKS, RDS, and the internet.

### Step 8: Create IAM Roles

**File: `iam-roles.tf`**
```hcl
# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Group Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# CodeBuild Service Role
resource "aws_iam_role" "codebuild" {
  name = "${var.cluster_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
    Version = "2012-10-17"
  })
}
```

**What this does**: Creates IAM roles with necessary permissions for EKS cluster, worker nodes, and CodeBuild.

### Step 9: Create EKS Cluster

**File: `eks-cluster.tf`**
```hcl
# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
  ]

  tags = {
    Name = var.cluster_name
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "${var.cluster_name}-nodes"
  }
}
```

**What this does**: Creates the EKS cluster and managed node group with auto-scaling capabilities.

### Step 10: Create RDS Database

**File: `rds.tf`**
```hcl
# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.cluster_name}-database"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "rentzone"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-database"
  }
}
```

**What this does**: Creates a MySQL RDS instance in private subnets with automated backups.

### Step 11: Create ECR Repository

**File: `ecr.tf`**
```hcl
# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "arm1-rentzone-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "arm1-rentzone-app"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

**What this does**: Creates ECR repository to store Docker images with lifecycle policy to manage storage costs.

### Step 12: Create CodeBuild Project

**File: `codebuild.tf`**
```hcl
# CodeBuild Project for Docker
resource "aws_codebuild_project" "docker" {
  name          = "${var.cluster_name}-docker-build"
  description   = "Build and push Docker images to ECR"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-docker.yml"
  }

  tags = {
    Name = "${var.cluster_name}-docker-build"
  }
}
```

**What this does**: Creates CodeBuild project for automated Docker image building and pushing to ECR.

### Step 13: Create Outputs

**File: `outputs.tf`**
```hcl
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}
```

### Step 14: Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply -auto-approve
```

**What happens**: Terraform creates all AWS resources. This takes about 15-20 minutes.

---

## Docker Configuration

### Step 1: Create Dockerfile

**File: `docker/Dockerfile`**
```dockerfile
# ARM1 Rentzone Application - Kubernetes Optimized Dockerfile
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    default-mysql-client \
    gettext-base \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy and extract Rentzone application
COPY rentzone.zip /tmp/rentzone.zip
RUN cd /tmp && unzip -q rentzone.zip && \
    rm -rf /var/www/html/* && \
    cp -r rentzone/* /var/www/html/ && \
    rm -rf /tmp/rentzone* && \
    chown -R www-data:www-data /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

# Create Laravel directories
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy environment template
COPY .env.template /var/www/html/.env

# Create health check file
RUN echo '<?php echo "OK"; ?>' > /var/www/html/health.php

# Copy startup script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start container
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
```

**What this does**: Creates a PHP/Apache container with all dependencies for the Rentzone application.

### Step 2: Create Apache Configuration

**File: `docker/apache-config.conf`**
```apache
<VirtualHost *:80>
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

### Step 3: Create Environment Template

**File: `docker/.env.template`**
```env
APP_NAME=Rentzone
APP_ENV=production
APP_KEY=base64:your-app-key-here
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=3306
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
```

### Step 4: Create Docker Entrypoint Script

**File: `docker/docker-entrypoint.sh`**
```bash
#!/bin/bash
set -e

# Replace environment variables in .env file
envsubst < /var/www/html/.env > /var/www/html/.env.tmp
mv /var/www/html/.env.tmp /var/www/html/.env

# Set proper permissions
chown www-data:www-data /var/www/html/.env
chmod 644 /var/www/html/.env

# Execute the main command
exec "$@"
```

### Step 5: Create BuildSpec for Docker

**File: `buildspec-docker.yml`**
```yaml
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: eu-west-1
    AWS_ACCOUNT_ID: 552704151745
    IMAGE_REPO_NAME: arm1-rentzone-app
    IMAGE_TAG: latest

phases:
  install:
    runtime-versions:
      docker: 20
    commands:
      - echo "Installing dependencies..."
      - nohup /usr/local/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://127.0.0.1:2376 --storage-driver=overlay2 &
      - timeout 15 sh -c "until docker info; do echo .; sleep 1; done"
      
  pre_build:
    commands:
      - echo "Logging into Amazon ECR..."
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
      
  build:
    commands:
      - echo "Building Docker image..."
      - cd docker
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $REPOSITORY_URI:$IMAGE_TAG
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $REPOSITORY_URI:latest
      
  post_build:
    commands:
      - echo "Pushing Docker image to ECR..."
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:latest
      - echo "Build completed on `date`"
      - printf '[{"name":"arm1-rentzone-app","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
      
artifacts:
  files:
    - imagedefinitions.json
  name: docker-artifacts
```

**What this does**: Defines how CodeBuild will build and push Docker images to ECR.

---

## Kubernetes Configuration

### Step 1: Create Deployment

**File: `k8s/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: arm1-rentzone-deployment
  namespace: default
  labels:
    app: arm1-rentzone
spec:
  replicas: 2
  selector:
    matchLabels:
      app: arm1-rentzone
  template:
    metadata:
      labels:
        app: arm1-rentzone
    spec:
      containers:
      - name: arm1-rentzone-app
        image: 552704151745.dkr.ecr.eu-west-1.amazonaws.com/arm1-rentzone-app:latest
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: arm1-db-secret
              key: DB_HOST
        - name: DB_DATABASE
          valueFrom:
            secretKeyRef:
              name: arm1-db-secret
              key: DB_DATABASE
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: arm1-db-secret
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: arm1-db-secret
              key: DB_PASSWORD
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: arm1-app-config
              key: APP_NAME
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: arm1-app-config
              key: APP_ENV
        - name: APP_URL
          valueFrom:
            configMapKeyRef:
              name: arm1-app-config
              key: APP_URL
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health.php
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health.php
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**What this does**: Defines how the application runs in Kubernetes with 2 replicas, health checks, and resource limits.

### Step 2: Create Service

**File: `k8s/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: arm1-rentzone-service
  namespace: default
  labels:
    app: arm1-rentzone
spec:
  selector:
    app: arm1-rentzone
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

**What this does**: Creates a service to expose the application within the cluster.

### Step 3: Create Ingress

**File: `k8s/ingress.yaml`**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: arm1-rentzone-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health.php
spec:
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: arm1-rentzone-service
            port:
              number: 80
```

**What this does**: Creates an Application Load Balancer to expose the application to the internet.

### Step 4: Create Secrets

**File: `k8s/secrets.yaml`**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: arm1-db-secret
  namespace: default
type: Opaque
data:
  DB_HOST: <base64-encoded-rds-endpoint>
  DB_DATABASE: cmVudHpvbmU=  # rentzone
  DB_USERNAME: YWRtaW4=      # admin
  DB_PASSWORD: <base64-encoded-password>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: arm1-app-config
  namespace: default
data:
  APP_NAME: "Rentzone"
  APP_ENV: "production"
  APP_URL: "http://your-domain.com"
```

**What this does**: Stores database credentials and application configuration securely.

---

## Database Setup

### Step 1: Connect to RDS

```bash
# Get RDS endpoint from Terraform output
terraform output rds_endpoint

# Connect using MySQL client
mysql -h your-rds-endpoint.amazonaws.com -u admin -p
```

### Step 2: Import Database Schema

```sql
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS rentzone;
USE rentzone;

-- Import your rentzone-db.sql file
SOURCE /path/to/rentzone-db.sql;

-- Verify tables
SHOW TABLES;
```

---

## Deployment Process

### Step 1: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name arm1-eks-cluster

# Verify connection
kubectl get nodes
```

### Step 2: Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=arm1-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install controller using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=arm1-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 3: Deploy Application

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get pods
kubectl get services
kubectl get ingress
```

### Step 4: Build and Push Docker Image

```bash
# Copy Rentzone application to docker directory
cp rentzone.zip docker/

# Commit and push to trigger CodeBuild
git add .
git commit -m "Deploy Rentzone application"
git push origin main
```

---

## Testing & Verification

### Step 1: Check Pod Status

```bash
# Check if pods are running
kubectl get pods -l app=arm1-rentzone

# Check pod logs
kubectl logs -l app=arm1-rentzone --tail=50

# Describe pod for detailed info
kubectl describe pod -l app=arm1-rentzone
```

### Step 2: Test Application Locally

```bash
# Port forward to test locally
kubectl port-forward service/arm1-rentzone-service 8080:80

# Open browser to http://localhost:8080
```

### Step 3: Check Database Connection

```bash
# Execute into pod
kubectl exec -it deployment/arm1-rentzone-deployment -- bash

# Test database connection
mysql -h your-rds-endpoint -u admin -p rentzone
```

### Step 4: Monitor Application

```bash
# Watch pod status
kubectl get pods -w

# Check ingress for external IP
kubectl get ingress

# View application logs
kubectl logs -f deployment/arm1-rentzone-deployment
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Pods Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common fixes:
# - Check image exists in ECR
# - Verify secrets are created
# - Check resource limits
```

#### 2. Database Connection Issues
```bash
# Verify RDS endpoint in secrets
kubectl get secret arm1-db-secret -o yaml

# Check security groups allow port 3306
# Verify RDS is in same VPC as EKS
```

#### 3. Load Balancer Not Working
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Verify ingress annotations
kubectl describe ingress arm1-rentzone-ingress
```

#### 4. Image Pull Errors
```bash
# Check ECR repository exists
aws ecr describe-repositories --region eu-west-1

# Verify CodeBuild completed successfully
# Check IAM permissions for ECR access
```

---

## Cost Management

### Daily Cost Estimates
- **EKS Cluster**: ~$2.40/day
- **EC2 Instances (2x t3.medium)**: ~$2.00/day
- **RDS (db.t3.micro)**: ~$0.50/day
- **NAT Gateway**: ~$1.50/day
- **Load Balancer**: ~$0.75/day
- **Total**: ~$7.15/day

### Cost Optimization Tips

1. **Use Spot Instances**:
```hcl
# In eks-cluster.tf
capacity_type = "SPOT"
instance_types = ["t3.medium", "t3.large"]
```

2. **Schedule Shutdown**:
```bash
# Stop cluster during non-business hours
# Use AWS Instance Scheduler
```

3. **Monitor Usage**:
```bash
# Set up billing alerts
# Use AWS Cost Explorer
# Monitor with CloudWatch
```

### Cleanup Resources

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Destroy Terraform infrastructure
terraform destroy -auto-approve

# Delete ECR images
aws ecr delete-repository --repository-name arm1-rentzone-app --force --region eu-west-1
```

---

## Summary

This guide covered:

1. **Infrastructure Setup**: Created VPC, EKS cluster, RDS database using Terraform
2. **Application Containerization**: Built Docker image with PHP/Apache
3. **Kubernetes Deployment**: Deployed application with auto-scaling and load balancing
4. **CI/CD Pipeline**: Automated builds with AWS CodeBuild
5. **Database Integration**: Connected application to RDS MySQL
6. **Monitoring & Troubleshooting**: Tools and techniques for maintenance

### Key Learning Points

- **Infrastructure as Code**: Terraform manages all AWS resources
- **Container Orchestration**: Kubernetes handles application scaling and health
- **Security**: Secrets management and network isolation
- **Automation**: CI/CD pipeline for continuous deployment
- **Cost Management**: Understanding and optimizing AWS costs

### Next Steps

1. **Add Monitoring**: Implement CloudWatch, Prometheus, or Grafana
2. **Implement HTTPS**: Add SSL/TLS certificates
3. **Add Caching**: Implement Redis or ElastiCache
4. **Backup Strategy**: Automated database and application backups
5. **Security Hardening**: Implement Pod Security Standards and Network Policies

This project demonstrates a production-ready deployment of a PHP application on AWS using modern DevOps practices and cloud-native technologies.