# ECR Repository for ARM1 Application
# Private container registry to store your rentzone application Docker images
resource "aws_ecr_repository" "arm1_app" {
  name                 = "arm1-rentzone-app"
  image_tag_mutability = "MUTABLE"  # Allow overwriting tags like 'latest'

  # Image Scanning Configuration - Security best practice
  image_scanning_configuration {
    scan_on_push = true  # Automatically scan images for vulnerabilities
  }

  # Encryption Configuration - Secure image storage
  encryption_configuration {
    encryption_type = "AES256"  # AWS managed encryption
  }

  tags = {
    Name        = "ARM1-rentzone-app"
    Type        = "Container-Registry"
    Environment = var.environment
  }
}

# ECR Repository Policy - Control access to the repository
resource "aws_ecr_repository_policy" "arm1_app_policy" {
  repository = aws_ecr_repository.arm1_app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# ECR Lifecycle Policy - Manage image retention and costs
resource "aws_ecr_lifecycle_policy" "arm1_app_lifecycle" {
  repository = aws_ecr_repository.arm1_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}