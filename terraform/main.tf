terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_secretsmanager_secret_version" "snowflake_creds" {
  secret_id = "vantagepoint/snowflake/config"
}

locals {
  sf_creds = jsondecode(data.aws_secretsmanager_secret_version.snowflake_creds.secret_string)
}

provider "snowflake" {
  organization_name = "XVPQLZL"
  account_name      = "SZC19072"
  user              = local.sf_creds["username"]
  password          = local.sf_creds["password"]
}
