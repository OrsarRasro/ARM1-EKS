# RDS Subnet Group
# Groups private data subnets for RDS deployment across multiple AZs
resource "aws_db_subnet_group" "main" {
  name       = "arm1-db-subnet-group"
  subnet_ids = [aws_subnet.private_data_1.id, aws_subnet.private_data_2.id]

  tags = {
    Name = "ARM1-db-subnet-group"
    Type = "Database"
  }
}

# RDS Parameter Group
# Custom parameter group for MySQL 8.0 optimization
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "arm1-mysql-params"

  tags = {
    Name = "ARM1-mysql-params"
    Type = "Database"
  }
}

# RDS Instance - Restored from Snapshot
# Restores ARM1 database from existing snapshot with all data intact
resource "aws_db_instance" "main" {
  # Snapshot Configuration - Restore from existing ARM1 snapshot
  snapshot_identifier = "arm1"  # Your snapshot ID
  
  # Basic Configuration
  identifier     = "arm1-rds-instance"
  engine         = "mysql"
  engine_version = "8.0.41"  # Match your snapshot version
  
  # Instance Configuration - Cost-optimized for dev/testing
  instance_class    = "db.t3.micro"  # Small instance for cost savings
  allocated_storage = 20             # Match your snapshot storage
  storage_type      = "gp2"          # General Purpose SSD
  
  # Database Configuration
  db_name  = "ARM1"   # Your application database name
  username = "ARM1"   # Master username from snapshot
  port     = 3306     # MySQL standard port
  
  # Network Configuration - Deploy in private data subnets
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  availability_zone      = "${var.aws_region}a"  # Single AZ for cost savings
  
  # Security Configuration
  publicly_accessible = false  # Keep database private for security
  
  # Backup Configuration - Minimal for dev environment
  backup_retention_period = 1     # 1 day retention for cost savings
  backup_window          = "03:00-04:00"  # Low traffic time
  maintenance_window     = "sun:04:00-sun:05:00"  # Sunday maintenance
  
  # Performance Configuration
  parameter_group_name = aws_db_parameter_group.main.name
  
  # High Availability - Disabled for cost savings in dev
  multi_az = false  # Single AZ deployment for cost optimization
  
  # Monitoring Configuration
  monitoring_interval = 0  # Disable enhanced monitoring for cost savings
  
  # Deletion Protection - Disabled for dev environment
  deletion_protection = false  # Allow deletion for dev/testing
  skip_final_snapshot = true   # Skip final snapshot on deletion
  
  # Storage Configuration
  storage_encrypted = false  # Disable encryption for cost savings in dev
  
  tags = {
    Name        = "ARM1-rds-instance"
    Type        = "Database"
    Environment = var.environment
    Snapshot    = "arm1"
  }
  
  # Lifecycle Management
  lifecycle {
    # Prevent accidental deletion of database
    prevent_destroy = false  # Allow destruction in dev environment
  }
}