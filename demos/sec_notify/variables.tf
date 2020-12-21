variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region used"
}

variable "env_name" {
  type        = string
  default     = ""
  description = "Environment name"
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "DNS domain name"
}

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "azs" {
  type    = list(any)
  default = []
}

variable "slack_notifications" {
  description = "Enable Slack notifications for GuardDuty findings"
  type        = bool
  default     = true
}

variable "sns_topic_slack" {
  description = "Slack SNS Topic Object."
  type        = object({ arn = string, name = string })
  default     = { arn = "", name = "" }
}

variable "slack_webhook_url" {
  description = "The URL of Slack webhook"
  type        = string
  default     = "https://bubu.test"
}

variable "slack_channel" {
  description = "The name of the channel in Slack for notifications"
  type        = string
  default     = "security"
}

variable "slack_username" {
  description = "The username that will appear on Slack messages"
  type        = string
  default     = "lambda-user"
}

variable "slack_emoji" {
  description = "A custom emoji that will appear on Slack messages"
  type        = string
  default     = ":aws:"
}
