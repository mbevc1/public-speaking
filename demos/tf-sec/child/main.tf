variable "test" {
  type        = string
  description = "Something"
  default     = null
  ephemeral   = true
}

output "something" {
  value     = "module: ${var.test}"
  ephemeral = true
}
