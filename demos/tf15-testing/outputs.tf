output "region" {
  value = var.region
}

output "a_pet" {
  value = random_pet.pet.id
}

output "bucket" {
  value = aws_s3_bucket.test.id
}
