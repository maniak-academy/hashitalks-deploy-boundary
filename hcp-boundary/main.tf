terraform {
  cloud {
    organization = "maniakacademy"
    workspaces {
      name = "maniakacademy-boundary"
    }
  }
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.10"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">=0.56.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.4"
    }
  }
}

provider "boundary" {
  addr                   = var.url
  auth_method_id         = var.auth_method_id
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "hashitalks-ntw"
  cidr = "10.20.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.20.1.0/24"]
  public_subnets  = ["10.20.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
