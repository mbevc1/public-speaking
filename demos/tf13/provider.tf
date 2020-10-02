terraform {
  required_providers {
    # This is the current syntax, which is still supported
    #random = ">= 2.7.0"

    # This is the new syntax. "source" and "version" are both
    # optional, though in the future "source" will be required for
    # any provider that isn't maintained by HashiCorp.
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = ">= 2.1.0"
    }
  }
}

provider "aws" {
  region = var.region
}
