terraform {
  required_providers {
    # This provider is only
    # available when running tests, so you shouldn't use it
    # in non-test modules.
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

provider "aws" {
  region = module.main.region
}

locals {
  bucket_name = format("mb-%s", module.main.a_pet)
}

module "main" {
  source = "../.."
}

resource "test_assertions" "s3" {
  # "component" is an unique identifier for this
  # particular set of assertions in the test results.
  component = "bucket"

  equal "name" {
    description = "Check bucket name"
    got         = local.bucket_name
    want        = module.main.bucket
  }

  check "name_prefix" {
    description = "Check for prefix"
    condition   = can(regex("^mb-", local.bucket_name))
  }
}

# We can also use data resources to respond to the
# behavior of the real remote system, rather than
# just to values within the Terraform configuration.
data "aws_s3_bucket" "s3_response" {
  bucket = module.main.bucket

  depends_on = [test_assertions.s3]
}

resource "test_assertions" "s3_response" {
  component = "bucket_response"

  check "valid_name" {
    description = "Has resource a valid name"
    condition   = can(data.aws_s3_bucket.s3_response.id == local.bucket_name)
  }
}
