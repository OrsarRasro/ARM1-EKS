# Application Load Balancer Security Group
# Allows inbound HTTP/HTTPS traffic from internet for public access to applications
resource "aws_security_group" "alb" {
  name        = "ARM1-alb-sg"
  description = "Security group for Application Load Balancer - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  # HTTP access from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-alb-sg"
    Type = "LoadBalancer"
  }
}

# SSH Security Group
# Allows SSH access for administrative purposes (consider restricting to your IP)
resource "aws_security_group" "ssh" {
  name        = "ARM1-ssh-sg"
  description = "Security group for SSH access - allows SSH from anywhere (restrict in production)"
  vpc_id      = aws_vpc.main.id

  # SSH access from internet (restrict this in production)
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP in production
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-ssh-sg"
    Type = "Administrative"
  }
}

# Web Application Security Group
# Allows traffic from ALB and SSH for EKS worker nodes and application pods
resource "aws_security_group" "webapp" {
  name        = "ARM1-webapp-sg"
  description = "Security group for web applications - allows traffic from ALB and SSH"
  vpc_id      = aws_vpc.main.id

  # HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # HTTPS from ALB
  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH access
  ingress {
    description     = "SSH access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
  }

  # Kubernetes API server communication - needed for kubectl commands
  ingress {
    description = "Kubernetes API server (kubectl access)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Node-to-node communication - allows pods to communicate across nodes
  ingress {
    description = "Node-to-node communication (inter-pod traffic)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-webapp-sg"
    Type = "Application"
  }
}

# Database Security Group
# Allows MySQL access only from web application security group for database isolation
resource "aws_security_group" "database" {
  name        = "ARM1-database-sg"
  description = "Security group for RDS MySQL - allows access only from web applications"
  vpc_id      = aws_vpc.main.id

  # MySQL access from web applications only
  ingress {
    description     = "MySQL from web applications"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp.id]
  }

  # No outbound rules needed for RDS (AWS manages this)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-database-sg"
    Type = "Database"
  }
}

# EKS Cluster Security Group
# Controls access to Kubernetes API server - needed for kubectl commands and cluster management
resource "aws_security_group" "eks_cluster" {
  name        = "ARM1-eks-cluster-sg"
  description = "Security group for EKS cluster control plane - allows API server communication"
  vpc_id      = aws_vpc.main.id

  # HTTPS for EKS API server - required for kubectl commands
  ingress {
    description = "HTTPS for EKS API server (kubectl access)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-eks-cluster-sg"
    Type = "EKS-Control-Plane"
  }
}

# EKS Node Group Security Group
# Allows worker nodes to communicate with each other and the cluster control plane
resource "aws_security_group" "eks_nodes" {
  name        = "ARM1-eks-nodes-sg"
  description = "Security group for EKS worker nodes - enables pod-to-pod communication"
  vpc_id      = aws_vpc.main.id

  # Node-to-node communication - allows pods on different nodes to talk
  ingress {
    description = "Node-to-node communication (pod-to-pod traffic)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Communication with EKS cluster - worker nodes receive instructions
  ingress {
    description     = "Communication with EKS cluster control plane"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # HTTPS from EKS cluster - secure communication with control plane
  ingress {
    description     = "HTTPS from EKS cluster (secure node registration)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # All outbound traffic allowed
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ARM1-eks-nodes-sg"
    Type = "EKS-Worker-Nodes"
  }
}

