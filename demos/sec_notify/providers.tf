terraform {
  required_version = "~> 0.14.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.10"
    }
  }
}

provider "aws" {
  region = var.region
}
