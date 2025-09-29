terraform {
  required_version = ">= 0.13" #Recommended CLI version ">= 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0" #Please refer official terraform provider documentation before updating provider version 
    }
  }
  backend "s3" {}
}

provider "aws" {
  # Configuration options 
  assume_role {
    role_arn = var.role_arn
  }
  region = var.region
}