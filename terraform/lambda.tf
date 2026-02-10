# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = "vantagepoint-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_access" {
  name = "lambda-s3-bedrock-secrets-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:us-east-1:022499024283:secret:vantagepoint/snowflake/config-*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      }
    ]
  })
}

# Snowflake connector layer
resource "aws_lambda_layer_version" "snowflake" {
  layer_name          = "snowflake-connector"
  s3_bucket           = aws_s3_bucket.glue_scripts.bucket
  s3_key              = "lambda/snowflake-layer.zip"
  compatible_runtimes = ["python3.11"]
}

# Zip the lambda code at plan time
data "archive_file" "list_transcripts" {
  type        = "zip"
  source_file = "${path.module}/../pipelines/lambda/list_transcripts/lambda_function.py"
  output_path = "${path.module}/../pipelines/lambda/list_transcripts/list_transcripts.zip"
}

data "archive_file" "process_transcripts" {
  type        = "zip"
  source_file = "${path.module}/../pipelines/lambda/process_transcripts/lambda_function.py"
  output_path = "${path.module}/../pipelines/lambda/process_transcripts/process_transcripts.zip"
}

# Lambda - list transcripts
resource "aws_lambda_function" "list_transcripts" {
  function_name    = "vantagepoint-list-transcripts"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  filename         = data.archive_file.list_transcripts.output_path
  source_code_hash = data.archive_file.list_transcripts.output_base64sha256

  environment {
    variables = {
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.bucket
    }
  }
}

# Lambda - process transcripts
resource "aws_lambda_function" "process_transcripts" {
  function_name    = "vantagepoint-process-transcripts"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512
  filename         = data.archive_file.process_transcripts.output_path
  source_code_hash = data.archive_file.process_transcripts.output_base64sha256

  layers = [aws_lambda_layer_version.snowflake.arn]

  environment {
    variables = {
      SECRET_NAME = "vantagepoint/snowflake/config"
    }
  }
}
