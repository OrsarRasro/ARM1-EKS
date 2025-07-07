terraform {
  backend "s3" {
    bucket         = "arm1teraformstatefile"
    key            = "rentzone-eks/terraform.tfstate"
    region         = "eu-west-1"
    profile        = "emmanuel"
    dynamodb_table = "arm1-state-lock"
  }
}