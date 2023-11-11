terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74"
    }
  }
}

provider "aws" {
  region = var.awsregion
}

terraform {
  backend "s3" {
    bucket = "sanofi-amer-datalab-terraformstate-dev"
    key    = "terraform/gen-ai.tfstate"
    region = "us-east-1"
  }
}