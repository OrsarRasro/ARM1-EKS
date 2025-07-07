# Create VPC - Virtual Private Cloud for ARM1 EKS infrastructure
# This provides isolated network environment for our Kubernetes cluster
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for EKS cluster communication
  enable_dns_support   = true  # Required for EKS cluster communication

  tags = {
    Name = "ARM1-vpc"
  }
}

# Create Internet Gateway - Provides internet access to public subnets
# Required for NAT gateways and public-facing load balancers
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ARM1-igw"
  }
}

# Create Public Subnets - For load balancers and NAT gateways
# These subnets have direct internet access via Internet Gateway
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = {
    Name = "ARM1-public-subnet-1"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = {
    Name = "ARM1-public-subnet-2"
    Type = "Public"
  }
}

# Create Private App Subnets - For EKS worker nodes and application pods
# These subnets access internet via NAT gateways for security
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                              = "ARM1-private-app-subnet-1"
    Type                              = "Private"
    "kubernetes.io/role/internal-elb" = "1"  # Required for EKS internal load balancers
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                              = "ARM1-private-app-subnet-2"
    Type                              = "Private"
    "kubernetes.io/role/internal-elb" = "1"  # Required for EKS internal load balancers
  }
}

# Create Private Data Subnets - For RDS database instances
# Isolated subnets for database security and compliance
resource "aws_subnet" "private_data_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "ARM1-private-data-subnet-1"
    Type = "Database"
  }
}

resource "aws_subnet" "private_data_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "ARM1-private-data-subnet-2"
    Type = "Database"
  }
}

# Create Public Route Table - Routes traffic from public subnets to Internet Gateway
# Enables direct internet access for resources in public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # All traffic
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ARM1-public-rt"
    Type = "Public"
  }
}

# Associate Public Subnets with Public Route Table
# Links public subnets to internet gateway routing
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Create Private Route Table 1 - Routes traffic from AZ-a private subnets to NAT Gateway 1
# Provides internet access for private resources in availability zone A
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ARM1-private-rt-1"
    Type = "Private"
    AZ   = "${var.aws_region}a"
  }
}

# Create Private Route Table 2 - Routes traffic from AZ-b private subnets to NAT Gateway 2
# Provides internet access for private resources in availability zone B
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ARM1-private-rt-2"
    Type = "Private"
    AZ   = "${var.aws_region}b"
  }
}

# Associate Private Subnets with Private Route Tables
# Links private app and data subnets to their respective NAT gateways
resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_data_1" {
  subnet_id      = aws_subnet.private_data_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_2.id
}

resource "aws_route_table_association" "private_data_2" {
  subnet_id      = aws_subnet.private_data_2.id
  route_table_id = aws_route_table.private_2.id
}