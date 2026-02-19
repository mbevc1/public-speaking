# Package the Lambda code into a zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/send-a-message.zip"
}

# IAM role Lambda will assume
resource "aws_iam_role" "lambda_role" {
  name = "send-a-message-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach basic execution permissions for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The Lambda function
resource "aws_lambda_function" "send_a_message" {
  function_name = "send-a-message"
  role          = aws_iam_role.lambda_role.arn

  runtime = "python3.14"
  handler = "send_a_message.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 128

  lifecycle {
    action_trigger {
      condition = true # Always
      events    = [after_create, after_update]
      actions   = [action.aws_lambda_invoke.message[0]]
    }
  }
}

# Optional: create a log group with retention (otherwise AWS creates it with never-expire)
resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${aws_lambda_function.send_a_message.function_name}"
  retention_in_days = 7
}

action "aws_lambda_invoke" "message" {
  count = 2 # Let's try more than one :)

  config {
    function_name = "send-a-message"
    log_type      = "Tail"
    payload = jsonencode({
      message = "This is the action payload!"
    })
  }
}

#resource "terraform_data" "example" {
#  input            = "trigger-lambda"
#  #triggers_replace = [0]
#
#  lifecycle {
#    action_trigger {
#      events  = [after_update] # after_create,
#      actions = [action.aws_lambda_invoke.message]
#    }
#  }
#}
