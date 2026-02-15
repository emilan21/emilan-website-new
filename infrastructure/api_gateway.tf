# API Gateway REST API
resource "aws_api_gateway_rest_api" "visitor_counter" {
  name = "visitor-counter-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Resources
resource "aws_api_gateway_resource" "counts" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  parent_id   = aws_api_gateway_rest_api.visitor_counter.root_resource_id
  path_part   = "counts"
}

resource "aws_api_gateway_resource" "get" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  parent_id   = aws_api_gateway_resource.counts.id
  path_part   = "get"
}

resource "aws_api_gateway_resource" "increment" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  parent_id   = aws_api_gateway_resource.counts.id
  path_part   = "increment"
}

# Methods with CORS
resource "aws_api_gateway_method" "get_post" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  resource_id   = aws_api_gateway_resource.get.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "increment_post" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  resource_id   = aws_api_gateway_resource.increment.id
  http_method   = "POST"
  authorization = "NONE"
}

# CORS Options methods
resource "aws_api_gateway_method" "get_options" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  resource_id   = aws_api_gateway_resource.get.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "increment_options" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  resource_id   = aws_api_gateway_resource.increment.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Lambda integrations
resource "aws_api_gateway_integration" "get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_counter.id
  resource_id             = aws_api_gateway_resource.get.id
  http_method             = aws_api_gateway_method.get_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_visit_count.invoke_arn
}

resource "aws_api_gateway_integration" "increment_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_counter.id
  resource_id             = aws_api_gateway_resource.increment.id
  http_method             = aws_api_gateway_method.increment_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.increment_visit_count.invoke_arn
}

# CORS mock integrations
resource "aws_api_gateway_integration" "get_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.get.id
  http_method = aws_api_gateway_method.get_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "increment_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.increment.id
  http_method = aws_api_gateway_method.increment_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Method responses for CORS
resource "aws_api_gateway_method_response" "get_options_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.get.id
  http_method = aws_api_gateway_method.get_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "increment_options_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.increment.id
  http_method = aws_api_gateway_method.increment_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integration responses for CORS
resource "aws_api_gateway_integration_response" "get_options" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.get.id
  http_method = aws_api_gateway_method.get_options.http_method
  status_code = aws_api_gateway_method_response.get_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "increment_options" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.increment.id
  http_method = aws_api_gateway_method.increment_options.http_method
  status_code = aws_api_gateway_method_response.increment_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Deployment
resource "aws_api_gateway_deployment" "visitor_counter" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.counts.id,
      aws_api_gateway_resource.get.id,
      aws_api_gateway_resource.increment.id,
      aws_api_gateway_method.get_post.id,
      aws_api_gateway_method.increment_post.id,
      aws_api_gateway_integration.get_lambda.id,
      aws_api_gateway_integration.increment_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.visitor_counter.id
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  stage_name    = var.stage_name
}
