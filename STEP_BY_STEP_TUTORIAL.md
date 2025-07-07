# Step-by-Step Tutorial: Deploy PHP Application on AWS EKS

## 🎯 What We're Building
We'll deploy a PHP Rentzone application on AWS using:
- **EKS (Kubernetes)** - To manage our containers
- **RDS MySQL** - For our database
- **Docker** - To package our application
- **Terraform** - To create AWS infrastructure
- **CodeBuild** - For automated deployments

## 📂 Complete Project Repository
**GitHub Repository:** https://github.com/OrsarRasro/ARM1-EKS

**What's in the repository:**
- All Terraform files for infrastructure
- Docker configuration files
- Kubernetes manifests
- Complete working example
- This tutorial document

**Note:** You'll create your own repository following this tutorial, but you can reference the complete working version above.

---

## 🔑 IMPORTANT: Information You Need to Customize

Before starting, here are ALL the places you'll need to replace with YOUR information:

### 1. AWS Account ID
**Where to find it:**
```bash
# After configuring AWS CLI, run:
aws sts get-caller-identity
# Look for "Account" field
```
**Where to replace:**
- `terraform.tfvars` → `aws_account_id = "YOUR_ACCOUNT_ID"`
- `buildspec-docker.yml` → `AWS_ACCOUNT_ID: YOUR_ACCOUNT_ID`
- `k8s/deployment.yaml` → `image: YOUR_ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/arm1-rentzone-app:latest`

### 2. GitHub Username
**Where to find it:** Your GitHub profile URL (github.com/YOUR_USERNAME)
**Where to replace:**
- `codebuild.tf` → `location = "https://github.com/YOUR_USERNAME/ARM1-EKS.git"`
- Step 4 → `git remote add origin https://github.com/YOUR_USERNAME/ARM1-EKS.git`

### 3. S3 Bucket Name (Must be Globally Unique)
**How to create unique name:** Add random numbers to `arm1-terraform-state-bucket`
**Where to replace:**
- `backend.tf` → `bucket = "arm1-terraform-state-bucket-YOUR_UNIQUE_NUMBER"`

### 4. Database Password
**Create your own secure password**
**Where to replace:**
- `terraform.tfvars` → `db_password = "YourSecurePassword123!"`

### 5. RDS Endpoint (Generated After Terraform Apply)
**How to get it:**
```bash
terraform output rds_endpoint
```
**Where to replace:**
- `k8s/secrets.yaml` → Encode this endpoint to base64

### 6. Base64 Encoded Values
**How to encode:**
```bash
# For RDS endpoint
echo -n "your-rds-endpoint.amazonaws.com" | base64

# For password
echo -n "YourSecurePassword123!" | base64
```
**Where to replace:**
- `k8s/secrets.yaml` → `DB_HOST` and `DB_PASSWORD` fields

---

## 📋 STEP 1: Install Required Tools

### Why These Tools?
- **AWS CLI**: Talk to AWS services
- **Terraform**: Create AWS infrastructure with code
- **kubectl**: Control Kubernetes
- **Git**: Version control
- **Docker**: Package applications

### 🔧 Installation Commands

**1. Install AWS CLI (Windows)**
```powershell
# Download and run installer
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I AWSCLIV2.msi /quiet'
```

**2. Install Terraform**
```powershell
# Download Terraform
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_windows_amd64.zip" -OutFile "terraform.zip"
Expand-Archive terraform.zip -DestinationPath "C:\terraform"
# Add C:\terraform to your PATH environment variable
```

**3. Install kubectl**
```powershell
# Download kubectl
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe" -OutFile "kubectl.exe"
# Move kubectl.exe to a directory in your PATH
```

**4. Install Git**
Download from: https://git-scm.com/download/win
**Installation:** Run the installer with default settings

**5. Install Visual Studio Code**
Download from: https://code.visualstudio.com/
**Installation:** Run installer with default settings

**Required Extensions for VS Code:**
1. Open VS Code
2. Click Extensions icon (left sidebar)
3. Install these extensions:
   - `Terraform` by HashiCorp
   - `Kubernetes` by Microsoft
   - `Docker` by Microsoft
   - `YAML` by Red Hat
   - `GitLens` by GitKraken

**6. Enable Hyper-V (CRITICAL for Docker)**
```powershell
# Run PowerShell as Administrator
# Enable Hyper-V feature
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Alternative: Use Windows Features
# Press Windows + R, type "optionalfeatures"
# Check "Hyper-V" and click OK
# Restart computer when prompted
```

**7. Install Docker Desktop**
Download from: https://www.docker.com/products/docker-desktop/
**Installation:** 
1. Run installer
2. Check "Use WSL 2 instead of Hyper-V" if prompted
3. Restart computer when prompted
4. Start Docker Desktop after restart

**7. Create Docker Hub Account (Optional but Recommended)**
1. Go to https://hub.docker.com/
2. Sign up for free account
3. Remember your username and password

**6. Add Tools to PATH (CRITICAL STEP)**
```bash
# Add these directories to your Windows PATH environment variable:
# C:\terraform
# Directory where you placed kubectl.exe
# Directory where you placed helm.exe
# Directory where you placed eksctl.exe
```
**How to add to PATH:**
1. Press Windows + R, type `sysdm.cpl`
2. Click "Environment Variables"
3. Under "System Variables", find "Path", click "Edit"
4. Click "New" and add each directory path
5. Click "OK" to save

### ✅ Verify Installations
```bash
aws --version
terraform --version
kubectl version --client
git --version
docker --version
```

### 🔧 Configure Docker (Optional)
```bash
# Login to Docker Hub (if you created account)
docker login
# Enter your Docker Hub username and password

# Test Docker
docker run hello-world
```

### ❗ Windows System Requirements Check
```powershell
# Check if Hyper-V is enabled
Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online

# Check Windows version (must be Windows 10 Pro/Enterprise or Windows 11)
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

**If Docker fails to start:**
1. Ensure Hyper-V is enabled
2. Restart computer
3. Check Windows version compatibility
4. Try "Reset to factory defaults" in Docker Desktop settings

---

## 📋 STEP 2: AWS Account Setup

### Why This Step?
We need AWS credentials to create resources and a user with proper permissions.

### 🔧 Setup Commands

**1. Create AWS Account**
- Go to aws.amazon.com
- Sign up for new account
- Add payment method

**2. Create IAM User**
```bash
# Login to AWS Console → IAM → Users → Create User
# Username: terraform-user
# Attach policy: AdministratorAccess
# Create access keys
```

**3. Configure AWS CLI**
```bash
aws configure
```
**Copy-Paste Values:**
```
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: eu-west-1
Default output format: json
```

**4. Test Connection**
```bash
aws sts get-caller-identity
```

---

## 📋 STEP 3: Create Project Structure

### Why This Structure?
Organized folders help separate infrastructure code, application code, and Kubernetes configurations.

### 🔧 Create Directories
```bash
mkdir ARM1-EKS
cd ARM1-EKS
mkdir docker k8s
```

### 📁 Final Structure
```
ARM1-EKS/
├── docker/          # Docker files
├── k8s/            # Kubernetes files
├── *.tf            # Terraform files
└── other files
```

---

## 📋 STEP 4: Initialize Git Repository

### Why Git?
Version control and trigger automated builds when we push code.

### 🔧 Create GitHub Account and Repository

**Step 1: Create GitHub Account**
1. Go to github.com
2. Sign up for free account
3. Verify your email

**Step 2: Generate SSH Key**
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
# Press Enter for default location
# Press Enter twice for no passphrase

# Copy public key to clipboard
cat ~/.ssh/id_rsa.pub
# Copy the entire output
```

**Step 3: Add SSH Key to GitHub**
1. Go to GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Title: "My Computer"
4. Paste the public key
5. Click "Add SSH key"

**Step 4: Create Personal Access Token**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Note: "ARM1-EKS Project"
4. Expiration: 90 days
5. Select scopes: `repo`, `workflow`, `admin:repo_hook`
6. Click "Generate token"
7. **COPY AND SAVE THIS TOKEN** - you won't see it again!

**Step 5: Create Repository**
1. Go to github.com and login
2. Click "New Repository"
3. Name: `ARM1-EKS`
4. Make it Public
5. Don't initialize with README
6. Click "Create Repository"

### 🔧 Configure Git Locally
```bash
# Configure Git with your information
git config --global user.name "Your Full Name"
git config --global user.email "your-email@example.com"

# Initialize repository
git init

# Add remote repository (use HTTPS with token)
git remote add origin https://YOUR_GITHUB_USERNAME:YOUR_PERSONAL_ACCESS_TOKEN@github.com/YOUR_GITHUB_USERNAME/ARM1-EKS.git
```

**❗ CUSTOMIZE THIS:**
- Replace `YOUR_GITHUB_USERNAME` with your GitHub username
- Replace `YOUR_PERSONAL_ACCESS_TOKEN` with the token you created
- Replace `Your Full Name` with your actual name
- Replace `your-email@example.com` with your email

**Create .gitignore file:**
```bash
# Create new file called .gitignore in ARM1-EKS directory
# Copy-paste this content into .gitignore:
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.pem
```
**How to create:** Right-click in ARM1-EKS folder → New → Text Document → Rename to `.gitignore`

---

## 📋 STEP 5: Create Terraform Backend

### Why Backend?
Stores Terraform state in AWS S3 for team collaboration and prevents conflicts.

### 🔧 Create backend.tf
**How to create:** Right-click in ARM1-EKS folder → New → Text Document → Rename to `backend.tf`
**Copy-paste this entire content:**
```hcl
terraform {
  backend "s3" {
    bucket = "arm1-terraform-state-bucket-unique-12345"
    key    = "arm1-eks/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

**❗ Important:** Change `unique-12345` to your own unique number.

---

## 📋 STEP 6: Configure Terraform Providers

### Why Providers?
Tells Terraform which cloud services to use and their versions.

### 🔧 Create providers.tf
**How to create:** Right-click in ARM1-EKS folder → New → Text Document → Rename to `providers.tf`
**Copy-paste this entire content:**
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

---

## 📋 STEP 7: Define Variables

### Why Variables?
Makes our code reusable and easier to modify without changing multiple files.

### 🔧 Create variables.tf
**Copy-paste this entire content:**
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

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "552704151745"
}
```

---

## 📋 STEP 8: Set Variable Values

### Why This File?
Contains actual values for our variables. Keep passwords secure!

### 🔧 Create terraform.tfvars
**Copy-paste and modify YOUR values:**
```hcl
aws_region     = "eu-west-1"
cluster_name   = "arm1-eks-cluster"
environment    = "production"
db_username    = "admin"
db_password    = "YourSecurePassword123!"
aws_account_id = "YOUR_AWS_ACCOUNT_ID"
```

**❗ Replace YOUR_AWS_ACCOUNT_ID with your actual AWS account ID**

---

## 📋 STEP 9: Create VPC and Networking

### Why VPC?
Creates isolated network for our resources with public and private subnets for security.

### 🔧 Create main.tf
**Copy-paste this entire content:**
```hcl
# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

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

# Public Subnets (for load balancers)
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

# Private Subnets (for applications and database)
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
```

---

## 📋 STEP 10: Create NAT Gateway

### Why NAT Gateway?
Allows private subnets to access internet for updates while staying secure.

### 🔧 Create natgateway.tf
**Copy-paste this entire content:**
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

# Public Route Table
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

# Private Route Tables
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

---

## 📋 STEP 11: Create Security Groups

### Why Security Groups?
Control network traffic - like firewalls for our resources.

### 🔧 Create security-groups.tf
**Copy-paste this entire content:**
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

---

## 📋 STEP 12: Create IAM Roles

### Why IAM Roles?
Give AWS services permission to work with each other securely.

### 🔧 Create iam-roles.tf
**Copy-paste this entire content:**
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

---

## 📋 STEP 13: Create EKS Cluster

### Why EKS?
Managed Kubernetes service that handles container orchestration and scaling.

### 🔧 Create eks-cluster.tf
**Copy-paste this entire content:**
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

---

## 📋 STEP 14: Create RDS Database

### Why RDS?
Managed MySQL database service with automated backups and scaling.

### 🔧 Create rds.tf
**Copy-paste this entire content:**
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

---

## 📋 STEP 15: Create ECR Repository

### Why ECR?
Stores our Docker images securely in AWS.

### 🔧 Create ecr.tf
**Copy-paste this entire content:**
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

---

## 📋 STEP 16: Create CodeBuild Project

### Why CodeBuild?
Automatically builds and pushes Docker images when we update code.

### 🔧 Create codebuild.tf
**Copy-paste this entire content:**
```hcl
# CodeBuild Project for Docker
resource "aws_codebuild_project" "docker" {
  name          = "${var.cluster_name}-docker-build"
  description   = "Build and push Docker images to ECR"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "GITHUB"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/YOUR_USERNAME/ARM1-EKS.git"
    git_clone_depth = 1
    buildspec       = "buildspec-docker.yml"
  }

  tags = {
    Name = "${var.cluster_name}-docker-build"
  }
}
```

**❗ Replace YOUR_USERNAME with your GitHub username**

---

## 📋 STEP 17: Create Outputs

### Why Outputs?
Shows important information after Terraform creates resources.

### 🔧 Create outputs.tf
**Copy-paste this entire content:**
```hcl
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
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

---

## 📋 STEP 18: Deploy Infrastructure

### Why This Step?
Creates all AWS resources using our Terraform code.

### 🔧 Create S3 Bucket FIRST
```bash
# Create the S3 bucket for Terraform state
aws s3 mb s3://arm1-terraform-state-bucket-YOUR_UNIQUE_NUMBER --region eu-west-1
```
**❗ Replace YOUR_UNIQUE_NUMBER with the same number you used in backend.tf**

### 🔧 Run Terraform Commands
```bash
# Initialize Terraform
terraform init

# See what will be created
terraform plan

# Create all resources (takes 15-20 minutes)
terraform apply -auto-approve
```

**⏱️ Wait Time:** 15-20 minutes for EKS cluster creation

---

## 📋 STEP 19: Configure kubectl

### Why kubectl?
Tool to control our Kubernetes cluster.

### 🔧 Setup kubectl
```bash
# Connect kubectl to our EKS cluster
aws eks update-kubeconfig --region eu-west-1 --name arm1-eks-cluster

# Test connection
kubectl get nodes
```

**Expected Output:**
```
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-0-10-xxx.eu-west-1.compute.internal   Ready    <none>   5m    v1.28.x
ip-10-0-11-xxx.eu-west-1.compute.internal   Ready    <none>   5m    v1.28.x
```

---

## 📋 STEP 20: Create Docker Configuration

### Why Docker?
Packages our PHP application with all dependencies into a container.

### 🔧 Create docker/Dockerfile
**Copy-paste this entire content:**
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

---

## 📋 STEP 21: Create Apache Configuration

### Why Apache Config?
Configures web server to serve our PHP application properly.

### 🔧 Create docker/apache-config.conf
**Copy-paste this entire content:**
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

---

## 📋 STEP 22: Create Environment Template

### Why Environment File?
Configures application settings like database connection.

### 🔧 Create docker/.env.template
**Copy-paste this entire content:**
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

---

## 📋 STEP 23: Create Docker Startup Script

### Why Startup Script?
Configures environment variables when container starts.

### 🔧 Create docker/docker-entrypoint.sh
**Copy-paste this entire content:**
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

---

## 📋 STEP 24: Create BuildSpec for CodeBuild

### Why BuildSpec?
Tells CodeBuild how to build and push our Docker image.

### 🔧 Create buildspec-docker.yml
**Copy-paste this entire content:**
```yaml
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: eu-west-1
    AWS_ACCOUNT_ID: 552704151745  # ❗ REPLACE WITH YOUR AWS ACCOUNT ID
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

**❗ Replace 552704151745 with your AWS Account ID**

---

## 📋 STEP 25: Add Rentzone Application

### Why This Step?
Adds the actual PHP application to our Docker image.

### 🔧 Copy Application Files
```bash
# Copy your rentzone.zip file to docker directory
cp rentzone.zip docker/rentzone.zip
```

**❗ CRITICAL: Get Rentzone Application**

You need the rentzone.zip file containing the PHP application. If you don't have it:
1. Download from your instructor/course materials
2. Or create a simple PHP application and zip it
3. The zip should contain PHP files for a web application
4. Place rentzone.zip in your ARM1-EKS root directory

---

## 📋 STEP 26: Create Kubernetes Secrets

### Why Secrets?
Stores database credentials securely in Kubernetes.

### 🔧 Get RDS Endpoint
```bash
# Get database endpoint
terraform output rds_endpoint
```

### 🔧 Create k8s/secrets.yaml
**Copy-paste and replace YOUR_VALUES:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: arm1-db-secret
  namespace: default
type: Opaque
data:
  DB_HOST: YOUR_BASE64_ENCODED_RDS_ENDPOINT  # ❗ ENCODE YOUR RDS ENDPOINT
  DB_DATABASE: cmVudHpvbmU=  # rentzone (already encoded)
  DB_USERNAME: YWRtaW4=      # admin (already encoded)
  DB_PASSWORD: YOUR_BASE64_ENCODED_PASSWORD  # ❗ ENCODE YOUR PASSWORD
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

### 🔧 Encode Values to Base64
```bash
# Encode RDS endpoint
echo -n "your-rds-endpoint.amazonaws.com" | base64

# Encode password
echo -n "YourSecurePassword123!" | base64
```

**Replace YOUR_BASE64_ENCODED_* with the encoded values**

---

## 📋 STEP 27: Create Kubernetes Deployment

### Why Deployment?
Defines how our application runs in Kubernetes with scaling and health checks.

### 🔧 Create k8s/deployment.yaml
**Copy-paste this entire content:**
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
        image: 552704151745.dkr.ecr.eu-west-1.amazonaws.com/arm1-rentzone-app:latest  # ❗ REPLACE 552704151745 WITH YOUR AWS ACCOUNT ID
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

**❗ Replace 552704151745 with your AWS Account ID**

---

## 📋 STEP 28: Create Kubernetes Service

### Why Service?
Exposes our application within the Kubernetes cluster.

### 🔧 Create k8s/service.yaml
**Copy-paste this entire content:**
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

---

## 📋 STEP 29: Create Kubernetes Ingress

### Why Ingress?
Creates a load balancer to expose our application to the internet.

### 🔧 Create k8s/ingress.yaml
**Copy-paste this entire content:**
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

---

## 📋 STEP 30: Install AWS Load Balancer Controller

### Why Load Balancer Controller?
Manages AWS Application Load Balancers for our Kubernetes ingress.

### 🔧 Install Controller
```bash
# Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Install eksctl (if not installed)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Windows_amd64.zip" -o "eksctl.zip"
unzip eksctl.zip
# Move eksctl.exe to your PATH

# Create service account
eksctl create iamserviceaccount \
  --cluster=arm1-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install Helm (if not installed)
curl https://get.helm.sh/helm-v3.12.0-windows-amd64.zip -o helm.zip
unzip helm.zip
# Move helm.exe to your PATH

# Install controller using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=arm1-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

**❗ Replace YOUR_ACCOUNT_ID with your AWS Account ID**

---

## 📋 STEP 31: Deploy Application to Kubernetes

### Why This Step?
Deploys our application configuration to the Kubernetes cluster.

### 🔧 Deploy Commands
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

---

## 📋 STEP 32: Build and Push Docker Image

### Why This Step?
Creates the Docker image with our application and pushes it to ECR.

### 🔧 Commit and Push Code
```bash
# Add all files to git
git add .

# Commit changes
git commit -m "Deploy Rentzone application to EKS"

# Push to GitHub (triggers CodeBuild)
git push origin main
```

**❗ If Git Push Fails:**
```bash
# Alternative: Use GitHub CLI (easier)
# Install GitHub CLI first: https://cli.github.com/
gh auth login
# Follow prompts to authenticate

# Then push
git push origin main
```

**❗ Or Use VS Code:**
1. Open VS Code in your ARM1-EKS folder
2. Click Source Control icon (left sidebar)
3. Stage all changes (+)
4. Enter commit message
5. Click Commit
6. Click Sync/Push

### 🔧 Monitor Build
```bash
# Check CodeBuild status in AWS Console
# Or use AWS CLI
aws codebuild list-builds-for-project --project-name arm1-eks-cluster-docker-build
```

---

## 📋 STEP 33: Setup Database

### Why Database Setup?
Import the Rentzone database schema and data.

### 🔧 Install MySQL Client FIRST
```bash
# Download MySQL Command Line Client
# Go to: https://dev.mysql.com/downloads/mysql/
# Download "MySQL Installer for Windows"
# Install only "MySQL Command Line Client"
```

### 🔧 Connect to RDS
```bash
# Get RDS endpoint (copy this value)
terraform output rds_endpoint

# Connect to database (replace with your actual endpoint)
mysql -h your-rds-endpoint.amazonaws.com -u admin -p
# Enter your database password when prompted
```

### 🔧 Import Database
```sql
-- Create database
CREATE DATABASE IF NOT EXISTS rentzone;
USE rentzone;

-- Import your SQL file (upload rentzone-db.sql to your system first)
SOURCE /path/to/rentzone-db.sql;

-- Verify tables
SHOW TABLES;
```

---

## 📋 STEP 34: Restart Deployment

### Why Restart?
Pulls the new Docker image with our application.

### 🔧 Restart Commands
```bash
# Wait for CodeBuild to complete (5-10 minutes)
# Then restart deployment
kubectl rollout restart deployment arm1-rentzone-deployment

# Check rollout status
kubectl rollout status deployment arm1-rentzone-deployment

# Verify pods are running
kubectl get pods -l app=arm1-rentzone
```

---

## 📋 STEP 35: Test Application

### Why Testing?
Verify our application is working correctly.

### 🔧 Test Commands
```bash
# Port forward to test locally
kubectl port-forward service/arm1-rentzone-service 8080:80

# Open browser to http://localhost:8080
```

### 🔧 Check Application Files
```bash
# Check what files are in the container
kubectl exec -it deployment/arm1-rentzone-deployment -- ls -la /var/www/html/

# Check application logs
kubectl logs -l app=arm1-rentzone --tail=50
```

---

## 📋 STEP 36: Get External URL

### Why External URL?
Access your application from anywhere on the internet.

### 🔧 Get URL Commands
```bash
# Check ingress for external URL
kubectl get ingress

# Wait for ADDRESS to be populated (5-10 minutes)
# Use the ADDRESS as your application URL
```

---

## 🎉 SUCCESS! Your Application is Deployed

### What You've Accomplished
✅ Created AWS infrastructure with Terraform  
✅ Built and deployed Docker containers  
✅ Set up Kubernetes cluster with EKS  
✅ Configured automated CI/CD pipeline  
✅ Connected application to RDS database  
✅ Exposed application with load balancer  

### Access Your Application
- **Local**: http://localhost:8080 (with port-forward)
- **Internet**: Use the ADDRESS from `kubectl get ingress`

---

## 💰 Cost Management

### Daily Costs (Approximate)
- EKS Cluster: $2.40/day
- EC2 Instances: $2.00/day  
- RDS Database: $0.50/day
- NAT Gateway: $1.50/day
- Load Balancer: $0.75/day
- **Total**: ~$7.15/day

### 🛑 Cleanup Resources
```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Destroy Terraform infrastructure
terraform destroy -auto-approve

# Delete ECR repository
aws ecr delete-repository --repository-name arm1-rentzone-app --force --region eu-west-1
```

---

## 🔧 Troubleshooting Common Issues

### Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Database Connection Issues
```bash
kubectl get secret arm1-db-secret -o yaml
# Verify RDS endpoint and credentials
```

### Image Pull Errors
```bash
aws ecr describe-repositories --region eu-west-1
# Check if CodeBuild completed successfully
```

### Load Balancer Not Working
```bash
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl describe ingress arm1-rentzone-ingress
```

---

## 📚 What You Learned

1. **Infrastructure as Code** - Using Terraform to manage AWS resources
2. **Containerization** - Packaging applications with Docker
3. **Container Orchestration** - Managing containers with Kubernetes
4. **Cloud Services** - Using AWS EKS, RDS, ECR, and CodeBuild
5. **CI/CD Pipelines** - Automated building and deployment
6. **Security** - Managing secrets and network security
7. **Monitoring** - Health checks and logging

Congratulations! You've successfully deployed a production-ready PHP application on AWS EKS! 🚀