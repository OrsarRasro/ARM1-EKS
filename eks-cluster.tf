# EKS Cluster
# Creates the Kubernetes control plane (master nodes) managed by AWS
# This is the "brain" of your Kubernetes cluster that manages all worker nodes and pods
resource "aws_eks_cluster" "main" {
  name     = "ARM1-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"  # Kubernetes version

  # VPC Configuration - Deploy control plane across private app subnets
  vpc_config {
    subnet_ids = [
      aws_subnet.private_app_1.id,
      aws_subnet.private_app_2.id,
      aws_subnet.public_1.id,      # Public subnets needed for load balancers
      aws_subnet.public_2.id
    ]
    
    # Security groups for cluster communication
    security_group_ids = [aws_security_group.eks_cluster.id]
    
    # API server endpoint configuration
    endpoint_private_access = true   # Allow private access from VPC
    endpoint_public_access  = true   # Allow public access for kubectl from internet
    
    # Restrict public access to specific IP ranges (optional - currently open)
    public_access_cidrs = ["0.0.0.0/0"]  # TODO: Restrict to your IP in production
  }

  # Logging Configuration - Enable control plane logs for troubleshooting
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name = "ARM1-eks-cluster"
    Type = "EKS-Control-Plane"
  }

  # Ensure IAM role is created before cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS Node Group
# Creates EC2 instances that will run your application pods
# These are the "worker" nodes where your containers actually run
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ARM1-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  
  # Deploy worker nodes in private app subnets for security
  subnet_ids = [
    aws_subnet.private_app_1.id,
    aws_subnet.private_app_2.id
  ]

  # Instance Configuration - Cost-optimized for dev environment
  instance_types = ["t3.medium"]  # 2 vCPU, 4GB RAM - good for small workloads
  ami_type       = "AL2_x86_64"   # Amazon Linux 2 optimized for EKS
  capacity_type  = "ON_DEMAND"    # Use on-demand instances (more reliable than spot)
  disk_size      = 20             # GB of storage per node

  # Auto Scaling Configuration - Automatically adjust number of nodes
  scaling_config {
    desired_size = 2  # Start with 2 nodes
    max_size     = 4  # Scale up to 4 nodes maximum
    min_size     = 1  # Scale down to 1 node minimum
  }

  # Update Configuration - How to handle node updates
  update_config {
    max_unavailable = 1  # Only update 1 node at a time to maintain availability
  }

  # Remote Access Configuration - SSH access to nodes (optional)
  remote_access {
    ec2_ssh_key = "ARM1-key-pair"  # TODO: Create this key pair or remove if not needed
    source_security_group_ids = [aws_security_group.ssh.id]
  }

  # Labels for Kubernetes scheduling
  labels = {
    Environment = var.environment
    NodeGroup   = "ARM1-workers"
  }

  tags = {
    Name = "ARM1-node-group"
    Type = "EKS-Worker-Nodes"
  }

  # Ensure all IAM policies are attached before creating nodes
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy_attachment.node_group_ecr_policy
  ]
}

# EKS Add-ons
# Additional components that enhance cluster functionality
# These provide essential services like DNS, networking, and storage

# CoreDNS - Provides DNS resolution for pods and services
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  
  tags = {
    Name = "ARM1-coredns-addon"
    Type = "EKS-Addon"
  }
}

# VPC CNI - Manages pod networking and IP address assignment
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  
  tags = {
    Name = "ARM1-vpc-cni-addon"
    Type = "EKS-Addon"
  }
}

# kube-proxy - Handles network routing for Kubernetes services
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  
  tags = {
    Name = "ARM1-kube-proxy-addon"
    Type = "EKS-Addon"
  }
}

# EBS CSI Driver - Enables persistent storage for pods
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
  
  tags = {
    Name = "ARM1-ebs-csi-addon"
    Type = "EKS-Addon"
  }
}