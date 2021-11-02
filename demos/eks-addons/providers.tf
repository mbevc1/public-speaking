terraform {
  required_version = ">= 1.0, < 2.0"

  required_providers {
    #random = {
    #  source  = "hashicorp/random"
    #  version = "~> 3.1"
    #}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.33"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.1"
    }
  }
}

# Providers configuration
provider "aws" {
  region = var.region
  #alias  = "x"

  #assume_role {
  #  role_arn     = "arn:aws:iam::xxx:role/TerraformExecutionRole"
  #  session_name = "Terraform"
  #  #external_id  = "EXTERNAL_ID"
  #}

  #default_tags {
  #  tags = {
  #    managed_by = "terraform"
  #  }
  #}
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
