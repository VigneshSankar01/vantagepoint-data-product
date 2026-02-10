# IAM role for Step Functions
resource "aws_iam_role" "step_functions" {
  name = "vantagepoint-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_invoke" {
  name = "stepfunctions-invoke-lambda"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.list_transcripts.arn,
        aws_lambda_function.process_transcripts.arn
      ]
    }]
  })
}

# State machine
resource "aws_sfn_state_machine" "transcript_pipeline" {
  name     = "vantagepoint-transcript-pipeline"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Process interaction transcripts through Bedrock and load to Snowflake"
    StartAt = "ListTranscripts"
    States = {
      ListTranscripts = {
        Type     = "Task"
        Resource = aws_lambda_function.list_transcripts.arn
        Next     = "ProcessFiles"
      }
      ProcessFiles = {
        Type           = "Map"
        ItemsPath      = "$.files"
        MaxConcurrency = 5
        Iterator = {
          StartAt = "ProcessSingleFile"
          States = {
            ProcessSingleFile = {
              Type     = "Task"
              Resource = aws_lambda_function.process_transcripts.arn
              Retry = [{
                ErrorEquals     = ["States.ALL"]
                IntervalSeconds = 10
                MaxAttempts     = 2
                BackoffRate     = 2.0
              }]
              End = true
            }
          }
        }
        Next = "Done"
      }
      Done = {
        Type = "Succeed"
      }
    }
  })
}
