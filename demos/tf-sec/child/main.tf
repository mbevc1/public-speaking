variable "test" {
  type        = string
  description = "Something"
  default     = null
  ephemeral   = true
}

output "something" {
  value     = var.test
  ephemeral = true
}
