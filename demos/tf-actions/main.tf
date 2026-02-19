resource "random_pet" "pet" {}

resource "random_string" "suffix" {
  length  = 4
  numeric = false
  upper   = false
  special = false
}

resource "aws_s3_bucket" "web" {
  bucket = "${random_pet.pet.id}-${random_string.suffix.result}"
}

# create the index.html object in the S3 bucket
resource "aws_s3_object" "index_html" {
  bucket         = aws_s3_bucket.web.bucket
  key            = "index.html"
  content_type   = "text/html"
  content_base64 = filebase64("${path.module}/html/index.html")

  lifecycle {
    action_trigger {
      # trigger an invalidation action after this object is updated
      events = [after_update]

      # invoke the cloudfront action
      actions = [action.aws_cloudfront_create_invalidation.update]
    }
  }
}

action "aws_cloudfront_create_invalidation" "update" {
  config {
    distribution_id = aws_cloudfront_distribution.web.id

    # control which paths are invalidated, or use "/*" for all paths
    paths = ["/*"]
  }
}
