output "pet" {
  value = random_pet.pet.id
}

# Also for_each attributes, also from providers
output "db-pass" {
  value     = var.db-pass
  sensitive = true
}
