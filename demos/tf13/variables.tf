variable "enabled" {
  type        = bool
  description = "Enable test module"
  default     = false
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"

  validation {
    # regex(...) fails if it cannot find a match
    # can(...) returns false if the code it contains produces an error
    condition     = can(regex("^eu-", var.region))
    error_message = "Only EU regions, must start with \"eu-\"."
  }
}
