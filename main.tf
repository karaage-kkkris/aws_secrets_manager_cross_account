terraform {
  required_version = ">=0.14.6"
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.69.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0.0"
    }
  }
}

data "aws_vpcs" "vpcs" {}

data "aws_caller_identity" "current" {}

# Fetch subnet ids from the assigned VPC identifier
data "aws_subnet_ids" "subnet_ids" {
  count  = length(var.subnet_ids) == 0 ? 1 : 0
  vpc_id = local.vpc_id
}

locals {
  vpc_id      = coalesce(var.vpc_id, tolist(data.aws_vpcs.vpcs.ids)[0])
  subnets     = length(var.subnet_ids) == 0 ? data.aws_subnet_ids.subnet_ids[0].ids : var.subnet_ids
  identifiers = var.kms_account_access_list == null ? [] : [for act in var.kms_account_access_list : "arn:aws:iam::${act}:root"]
}
