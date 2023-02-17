terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    waypoint = {
      source  = "hashicorp-dev-advocates/waypoint"
      version = "~>0.3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

resource "waypoint_project" "deployer" {

  project_name           = "deployer"
  remote_runners_enabled = false

  data_source_git {
    git_url                   = "https://github.com/mbevc1/public-speaking"
    git_path                  = "demos/waypoint"
    git_ref                   = "HEAD"
    file_change_signal        = "some-signal"
    git_poll_interval_seconds = 15
  }

  app_status_poll_seconds = 12

  project_variables = {
    region = var.region
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

# ECR
resource "aws_ecr_repository" "waypoint" {
  name                 = "waypoint"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "waypoint" {
  repository = aws_ecr_repository.waypoint.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 1 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

provider "waypoint" {
  waypoint_addr = "api.hashicorp.cloud:443"
  token         = "" # e.g. from HCP platform
}
