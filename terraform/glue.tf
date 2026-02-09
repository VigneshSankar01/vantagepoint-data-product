# IAM role for Glue
resource "aws_iam_role" "glue" {
  name = "vantagepoint-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_secrets" {
  name = "glue-s3-secrets-access"
  role = aws_iam_role.glue.id

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
          "${aws_s3_bucket.data_lake.arn}/*",
          aws_s3_bucket.glue_scripts.arn,
          "${aws_s3_bucket.glue_scripts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:us-east-1:022499024283:secret:vantagepoint/snowflake/config-*"
      }
    ]
  })
}

# Glue connection for Snowflake networking
resource "aws_glue_connection" "snowflake" {
  name            = "vantagepoint-snowflake-conn"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = aws_subnet.glue_private.availability_zone
    security_group_id_list = [aws_security_group.glue.id]
    subnet_id              = aws_subnet.glue_private.id
  }
}

# Glue job - usage logs ingestion
resource "aws_glue_job" "usage_logs_ingestion" {
  name     = "vantagepoint-usage-logs-ingestion"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/ingest_usage_logs.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"     = "python"
    "--extra-jars"       = "s3://${aws_s3_bucket.glue_scripts.bucket}/jars/spark-snowflake_2.12-2.16.0-spark_3.3.jar,s3://${aws_s3_bucket.glue_scripts.bucket}/jars/snowflake-jdbc-3.17.0.jar"
    "--TempDir"          = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    "--enable-metrics"   = "true"
    "--SECRET_NAME"      = "vantagepoint/snowflake/config"
    "--DATA_LAKE_BUCKET" = aws_s3_bucket.data_lake.bucket
  }

  connections = [aws_glue_connection.snowflake.name]

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}
