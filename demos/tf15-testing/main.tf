## Bucket
resource "random_pet" "pet" {
}

locals {
  bucket_name = "mb-${random_pet.pet.id}"
}

resource "aws_s3_bucket" "test" {
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
