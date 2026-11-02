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
  enable_nat_gateway = true
  tags               = local.tags
}

module "ecs_service" {
  source             = "../../modules/ecs-service"
  name               = "platform-sim-dev"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  container_image    = "public.ecr.aws/nginx/nginx:stable"
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

output "alb_dns_name" {
  value = module.ecs_service.alb_dns_name
}

variable "alert_email" {
  type        = string
  description = "Email for SNS alarm notifications (set via TF_VAR_alert_email)"
}

module "alarms" {
  source                  = "../../modules/alarms"
  name                    = "platform-sim-dev"
  alert_email             = var.alert_email
  alb_arn_suffix          = module.ecs_service.alb_arn_suffix
  target_group_arn_suffix = module.ecs_service.target_group_arn_suffix
  cluster_name            = module.ecs_service.cluster_name
  service_name            = module.ecs_service.service_name
  tags                    = local.tags
}
