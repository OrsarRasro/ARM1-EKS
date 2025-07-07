# Create Elastic IPs for NAT Gateways
# Static public IP addresses required for NAT gateways to provide consistent outbound internet access
resource "aws_eip" "nat_1" {
  domain = "vpc"  # Allocate EIP in VPC scope
  
  tags = {
    Name = "ARM1-eip-nat-1"
    AZ   = "${var.aws_region}a"
  }
}

resource "aws_eip" "nat_2" {
  domain = "vpc"  # Allocate EIP in VPC scope
  
  tags = {
    Name = "ARM1-eip-nat-2"
    AZ   = "${var.aws_region}b"
  }
}

# Create NAT Gateway 1 - Provides internet access for private subnets in AZ-a
# Allows EKS nodes and RDS to download updates and communicate with AWS services
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id  # Must be in public subnet

  tags = {
    Name = "ARM1-nat-gateway-1"
    AZ   = "${var.aws_region}a"
  }

  depends_on = [aws_internet_gateway.main]  # Ensure IGW exists first
}

# Create NAT Gateway 2 - Provides internet access for private subnets in AZ-b
# Ensures high availability - if one AZ fails, the other continues working
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id  # Must be in public subnet

  tags = {
    Name = "ARM1-nat-gateway-2"
    AZ   = "${var.aws_region}b"
  }

  depends_on = [aws_internet_gateway.main]  # Ensure IGW exists first
}

# Add NAT Gateway routes to private route tables
# Routes all outbound internet traffic from private subnets through NAT gateways
resource "aws_route" "private_1_nat" {
  route_table_id         = aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"  # All internet traffic
  nat_gateway_id         = aws_nat_gateway.nat_1.id
}

resource "aws_route" "private_2_nat" {
  route_table_id         = aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"  # All internet traffic
  nat_gateway_id         = aws_nat_gateway.nat_2.id
}