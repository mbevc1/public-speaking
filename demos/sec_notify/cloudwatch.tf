# CloudWatch Event
resource "aws_cloudwatch_event_rule" "gd" {
  name          = "guardduty-finding-events"
  description   = "AWS GuardDuty event findings"
  event_pattern = file("${path.module}/event-pattern.json")
}

# More details about the response syntax can be found here:
# https://docs.aws.amazon.com/guardduty/latest/ug/get-findings.html#get-findings-response-syntax
resource "aws_cloudwatch_event_target" "slack" {
  count = var.slack_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.gd.name
  target_id = "lambda"
  arn       = module.notify_slack.lambda_arn

  #input_transformer {
  #  input_paths = {
  #    title       = "$.detail.title"
  #    description = "$.detail.description"
  #    eventTime   = "$.detail.service.eventFirstSeen"
  #    region      = "$.detail.region"
  #  }

  #  input_template = "\"GuardDuty finding in <region> first seen at <eventTime>: <title> <description>\""
  #}
}

resource "aws_sns_topic" "slack" {
  name = "slack-alerts"
}

resource "aws_lambda_permission" "slack_notifier" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.notify_slack.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack.arn
}

resource "aws_sns_topic_subscription" "slack_alerts" {
  topic_arn              = aws_sns_topic.slack.arn
  protocol               = "lambda"
  endpoint               = module.notify_slack.lambda_arn
  endpoint_auto_confirms = true
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.notify_slack.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.gd.arn
  #qualifier     = aws_lambda_alias.slack_alias.name
}

#resource "aws_lambda_alias" "slack_alias" {
#  name             = "slackalias"
#  description      = "Slack notification Lambda"
#  function_name    = module.notify_slack.lambda_function_name
#  function_version = "$LATEST"
#}

module "notify_slack" {
  source = "./terraform-aws-lambda"

  artifact              = "${path.module}/notify_slack.zip"
  artifact_base64sha256 = data.archive_file.artifact.output_base64sha256
  name                  = "slack_notifier"
  description           = "GuardDuty Slack notifications"
  handler               = "notify_slack.lambda_handler"
  runtime               = "python3.8"
  timeout               = "30"

  environment_vars = {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SLACK_CHANNEL     = var.slack_channel
      SLACK_USERNAME    = var.slack_username
      #SLACK_EMOJI       = var.slack_emoji
    }
  }
}
