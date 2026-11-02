terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "aws-platform-sim-tfstate-038269110424"
    key            = "envs/dev/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "aws-platform-sim-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

locals {
  tags = {
    project = "aws-platform-sim"
    env     = "dev"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  name               = "platform-sim-dev"
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  tags               = local.tags
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
