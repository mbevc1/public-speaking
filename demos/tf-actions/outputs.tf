output "lambda_function_name" {
  value = aws_lambda_function.send_a_message.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.send_a_message.arn
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.web.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.web.bucket
}
