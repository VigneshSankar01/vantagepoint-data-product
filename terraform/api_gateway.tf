# Zip Lambda code
data "archive_file" "rag_query" {
  type        = "zip"
  source_file = "${path.module}/../pipelines/lambda/rag_query/lambda_function.py"
  output_path = "${path.module}/../pipelines/lambda/rag_query/rag_query.zip"
}

data "archive_file" "get_dashboard_data" {
  type        = "zip"
  source_file = "${path.module}/../pipelines/lambda/get_dashboard_data/lambda_function.py"
  output_path = "${path.module}/../pipelines/lambda/get_dashboard_data/get_dashboard_data.zip"
}

# RAG Query Lambda
resource "aws_lambda_function" "rag_query" {
  function_name    = "vantagepoint-rag-query"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 120
  memory_size      = 512
  filename         = data.archive_file.rag_query.output_path
  source_code_hash = data.archive_file.rag_query.output_base64sha256

  layers = [aws_lambda_layer_version.snowflake.arn]

  environment {
    variables = {
      SECRET_NAME = "vantagepoint/snowflake/config"
    }
  }
}

# Dashboard Data Lambda
resource "aws_lambda_function" "get_dashboard_data" {
  function_name    = "vantagepoint-get-dashboard-data"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.get_dashboard_data.output_path
  source_code_hash = data.archive_file.get_dashboard_data.output_base64sha256

  layers = [aws_lambda_layer_version.snowflake.arn]

  environment {
    variables = {
      SECRET_NAME = "vantagepoint/snowflake/config"
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "vantagepoint-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# Dashboard endpoint
resource "aws_apigatewayv2_integration" "dashboard" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_dashboard_data.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "dashboard" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/dashboard"
  target    = "integrations/${aws_apigatewayv2_integration.dashboard.id}"
}

resource "aws_lambda_permission" "dashboard_apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_dashboard_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# RAG endpoint
resource "aws_apigatewayv2_integration" "rag" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.rag_query.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "rag" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /api/rag"
  target    = "integrations/${aws_apigatewayv2_integration.rag.id}"
}

resource "aws_lambda_permission" "rag_apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rag_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Output the API URL
output "api_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}
