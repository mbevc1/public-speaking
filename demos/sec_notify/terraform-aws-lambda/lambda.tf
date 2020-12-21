data "aws_iam_policy_document" "sts_assumerole_by_lambda" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.sts_assumerole_by_lambda.json
  path               = "/roles/lambda/"
}

resource "aws_iam_role_policy_attachment" "logs" {
  count = var.attach_cloudwatch_logs_policy ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 30
}

resource "aws_lambda_function" "lambda" {
  filename         = var.artifact
  function_name    = var.name
  description      = var.description
  handler          = var.handler
  role             = aws_iam_role.lambda.arn
  source_code_hash = var.artifact_base64sha256
  runtime          = var.runtime
  timeout          = var.timeout

  dynamic "environment" {
    for_each = var.environment_vars

    content {
      variables = environment.value
    }
  }

  # TODO: Required if we want to run Lambdas inside the VPC
  #vpc_config {
  #  subnet_ids         = []
  #  security_group_ids = []
  #}
}
