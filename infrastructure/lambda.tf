data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-visitor-counter-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "get_counts_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_visit_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_counter.execution_arn}/*/POST/counts/get"
}

resource "aws_lambda_permission" "increment_counts_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increment_visit_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_counter.execution_arn}/*/POST/counts/increment"
}

# Package Lambda functions from local backend directory
# Using relative path from infrastructure/ to backend/
data "archive_file" "get_visit_count" {
  type        = "zip"
  source_file = "${path.module}/../backend/get_visit_count.py"
  output_path = "${path.module}/get_visit_count_payload.zip"
}

data "archive_file" "increment_visit_count" {
  type        = "zip"
  source_file = "${path.module}/../backend/increment_visit_count.py"
  output_path = "${path.module}/increment_visit_count_payload.zip"
}

data "archive_file" "delete_visit_count" {
  type        = "zip"
  source_file = "${path.module}/../backend/delete_visit_count.py"
  output_path = "${path.module}/delete_visit_count_payload.zip"
}

# Lambda functions
resource "aws_lambda_function" "get_visit_count" {
  filename         = data.archive_file.get_visit_count.output_path
  function_name    = "get_visit_count"
  role             = aws_iam_role.lambda_role.arn
  handler          = "get_visit_count.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.get_visit_count.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access,
  ]
}

resource "aws_lambda_function" "increment_visit_count" {
  filename         = data.archive_file.increment_visit_count.output_path
  function_name    = "increment_visit_count"
  role             = aws_iam_role.lambda_role.arn
  handler          = "increment_visit_count.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.increment_visit_count.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access,
  ]
}

resource "aws_lambda_function" "delete_visit_count" {
  filename         = data.archive_file.delete_visit_count.output_path
  function_name    = "delete_visit_count"
  role             = aws_iam_role.lambda_role.arn
  handler          = "delete_visit_count.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.delete_visit_count.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb_access,
  ]
}

# CloudWatch log groups for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/visitor-counter"
  retention_in_days = 7
}
