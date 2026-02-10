# Read GitHub token from Secrets Manager
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = "vantagepoint/github/token"
}

# Amplify App
resource "aws_amplify_app" "frontend" {
  name       = "vantagepoint-frontend"
  repository = "https://github.com/VigneshSankar01/vantagepoint-data-product"

  access_token = data.aws_secretsmanager_secret_version.github_token.secret_string

  build_spec = <<-EOT
    version: 1
    applications:
      - frontend:
          phases:
            preBuild:
              commands:
                - npm ci
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: dist
            files:
              - '**/*'
          cache:
            paths:
              - node_modules/**/*
        appRoot: frontend
  EOT

  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }

  environment_variables = {
    AMPLIFY_MONOREPO_APP_ROOT = "frontend"
  }
}

# Branch - main
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "master"

  framework = "React"
  stage     = "PRODUCTION"

  enable_auto_build = true
}

# Output
output "amplify_url" {
  value = "https://master.${aws_amplify_app.frontend.default_domain}"
}
