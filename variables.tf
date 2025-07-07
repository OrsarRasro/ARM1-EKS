# Environment Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ARM1-eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
