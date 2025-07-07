# VPC Outputs - Core network infrastructure identifiers
# Used by EKS cluster and other AWS services for network configuration
output "vpc_id" {
  description = "ARM1 VPC ID - Required for EKS cluster creation"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "ARM1 VPC CIDR block - Network range for security group rules"
  value       = aws_vpc.main.cidr_block
}

# Public Subnet Outputs - For load balancers and internet-facing resources
# EKS uses these for Application Load Balancers and NAT gateways
output "public_subnet_1_id" {
  description = "ARM1 Public Subnet 1 ID - AZ-a for load balancers"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ARM1 Public Subnet 2 ID - AZ-b for load balancers"
  value       = aws_subnet.public_2.id
}

# Private App Subnet Outputs - For EKS worker nodes and application pods
# These subnets host the Kubernetes cluster nodes and application workloads
output "private_app_subnet_1_id" {
  description = "ARM1 Private App Subnet 1 ID - EKS nodes in AZ-a"
  value       = aws_subnet.private_app_1.id
}

output "private_app_subnet_2_id" {
  description = "ARM1 Private App Subnet 2 ID - EKS nodes in AZ-b"
  value       = aws_subnet.private_app_2.id
}

# Private Data Subnet Outputs - For RDS database instances
# Isolated network layer for database security and compliance
output "private_data_subnet_1_id" {
  description = "ARM1 Private Data Subnet 1 ID - RDS in AZ-a"
  value       = aws_subnet.private_data_1.id
}

output "private_data_subnet_2_id" {
  description = "ARM1 Private Data Subnet 2 ID - RDS in AZ-b"
  value       = aws_subnet.private_data_2.id
}

# Internet Gateway Output - For public internet access
# Required for routing configuration and troubleshooting
output "internet_gateway_id" {
  description = "ARM1 Internet Gateway ID - Public internet access point"
  value       = aws_internet_gateway.main.id
}

# NAT Gateway Outputs - For private subnet internet access
# Used for monitoring costs and troubleshooting connectivity issues
output "nat_gateway_1_id" {
  description = "ARM1 NAT Gateway 1 ID - Internet access for AZ-a private subnets"
  value       = aws_nat_gateway.nat_1.id
}

output "nat_gateway_2_id" {
  description = "ARM1 NAT Gateway 2 ID - Internet access for AZ-b private subnets"
  value       = aws_nat_gateway.nat_2.id
}