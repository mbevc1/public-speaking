## Buckets
resource "random_pet" "pet" {
}

locals {
  bucket_names = ["${random_pet.pet.id}-a", "${random_pet.pet.id}-b"]

  resources = {
    bucket1 = "${local.bucket_names[0]}-1"
    bucket2 = "${local.bucket_names[1]}-2"
  }
}

module "buckets2" {
  source = "terraform-aws-modules/s3-bucket/aws"
  providers = {
    aws = aws
  }

  for_each = local.resources

  bucket                  = each.value
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = true

  # direct dependency is preferred
  depends_on = [module.buckets1]
}

module "buckets1" {
  source = "terraform-aws-modules/s3-bucket/aws"
  providers = {
    aws = aws
  }

  count = length(local.bucket_names)

  bucket                  = local.bucket_names[count.index]
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = true
}

## Local module
locals {
  var_map = {
    name1 = "value1"
    name2 = "value2"
  }
}

module "test" {
  source = "./mod"
  i      = "test"
}

module "c" {
  count  = var.enabled ? 3 : 0
  source = "./mod"
  i      = "multi-test"
}

module "f" {
  # Create an instance of this module for each element in locals.tag_Name_map
  for_each = local.var_map

  source     = "./mod"
  i          = each.value # use each value from the map
  depends_on = [module.c]
}
