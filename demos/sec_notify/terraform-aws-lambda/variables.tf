variable "artifact" {
  type = string
}

variable "artifact_base64sha256" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "timeout" {
  type    = string
  default = 3 # AWS Lambda default timeout, in seconds
}

variable "attach_cloudwatch_logs_policy" {
  type    = bool
  default = true
}

variable "environment_vars" {
  type    = map
  default = null
}
