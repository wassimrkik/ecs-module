data "aws_vpc" "main" {
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_security_group" "internet_access" {
  name = "internet-access"
}

data "aws_security_group" "default" {
  name = "default"
}

data "aws_route53_zone" "selected" {
  name         = "p${local.aws_account_id}.aws-${lookup(local.region_mapping, local.aws_region_name)}.sanofi.com"
  private_zone = true
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}
data "aws_region" "region" {

}

locals {
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region_name = data.aws_region.current.name
  region_mapping = {
    us-east-1 = "amer"
    eu-west-1 = "emea"
  }
}