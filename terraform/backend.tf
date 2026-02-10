terraform {
  backend "s3" {
    bucket         = "vantagepoint-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vantagepoint-terraform-lock"
    encrypt        = true
  }
}
