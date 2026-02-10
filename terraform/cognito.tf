# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "vantagepoint-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

# App Client (for the React frontend)
resource "aws_cognito_user_pool_client" "frontend" {
  name         = "vantagepoint-frontend"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = false
}

# Create a test user
resource "null_resource" "create_test_user" {
  depends_on = [aws_cognito_user_pool.main]

  provisioner "local-exec" {
    command = <<-EOT
      aws cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.main.id} --username user123@vantagepoint.com --user-attributes Name=email,Value=user123@vantagepoint.com --temporary-password TempPass123 --message-action SUPPRESS
      aws cognito-idp admin-set-user-password --user-pool-id ${aws_cognito_user_pool.main.id} --username user123@vantagepoint.com --password VantageAdvantage2026 --permanent
    EOT
  }
}

# Outputs
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}
