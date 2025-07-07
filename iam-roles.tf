# EKS Cluster Service Role
# This role allows EKS service to manage AWS resources on your behalf
# Think of it as the "manager" role that creates load balancers, manages networking, etc.
resource "aws_iam_role" "eks_cluster_role" {
  name = "ARM1-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ARM1-eks-cluster-role"
    Type = "EKS-Cluster-Role"
  }
}

# Attach AWS managed policy for EKS cluster operations
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Role
# This role allows EC2 instances to join the EKS cluster as worker nodes
# Think of it as the "worker" role that allows nodes to register and communicate
resource "aws_iam_role" "eks_node_group_role" {
  name = "ARM1-eks-node-group-role"

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

  tags = {
    Name = "ARM1-eks-node-group-role"
    Type = "EKS-Node-Group-Role"
  }
}

# Attach AWS managed policies for EKS worker nodes
# These policies allow nodes to join cluster, pull images, and manage networking
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# EKS Pod Execution Role (for Fargate - optional but good to have)
# This role allows pods to access AWS services like ECR, RDS, etc.
# Think of it as the "application" role for your running containers
resource "aws_iam_role" "eks_pod_execution_role" {
  name = "ARM1-eks-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ARM1-eks-pod-execution-role"
    Type = "EKS-Pod-Execution-Role"
  }
}

# Attach AWS managed policy for pod execution
resource "aws_iam_role_policy_attachment" "eks_pod_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_pod_execution_role.name
}

# Custom Policy for ECR Access
# Allows pods to push/pull images from our ARM1 ECR repository
resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ARM1-ecr-access-policy"
  description = "Policy for accessing ARM1 ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          aws_ecr_repository.arm1_app.arn,
          "${aws_ecr_repository.arm1_app.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "ARM1-ecr-access-policy"
    Type = "Custom-Policy"
  }
}

# Attach ECR access policy to node group role
resource "aws_iam_role_policy_attachment" "node_group_ecr_policy" {
  policy_arn = aws_iam_policy.ecr_access_policy.arn
  role       = aws_iam_role.eks_node_group_role.name
}

# Custom Policy for RDS Access (for applications)
# Allows pods to connect to ARM1 RDS database
resource "aws_iam_policy" "rds_access_policy" {
  name        = "ARM1-rds-access-policy"
  description = "Policy for accessing ARM1 RDS database"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds-db:connect"
        ]
        Resource = [
          aws_db_instance.main.arn
        ]
      }
    ]
  })

  tags = {
    Name = "ARM1-rds-access-policy"
    Type = "Custom-Policy"
  }
}