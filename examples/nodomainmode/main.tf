provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module "rest-api" {
  source = "../../"

  api_name      = "my-app-dev"
  description   = "Development API for the My App service (No Domain Mode)."
  endpoint_type = "REGIONAL"

  // Custom Domain Configuration
  // Explicitly disable custom domains and provide no domain names
  create_api_domain_name = false
  domain_names           = null

  // API Resource Policy
  // Required if create_rest_api_policy is true (default)
  rest_api_policy = templatefile("${path.module}/api_policy.json.tpl", {})

  // API Definition
  openapi_definition = templatefile("${path.module}/openapi.yaml",
    {
      endpoint_uri             = "https://example.com/my_app_path"
      vpc_link_id              = "123456"
      lambda_invoke_arn        = "arn:aws:lambda:us-east-1:111111111111:function:my-func"
      authorizer_invoke_arn    = "arn:aws:lambda:us-east-1:111111111111:function:my-func"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-role"
    }
  )

  // Stage Settings
  stage_names       = ["dev"]
  log_group_name    = "/aws/apigateway/access/my_app/dev"
  access_log_format = templatefile("${path.module}/log_format.json.tpl", {})

  // Execution Role
  cloudwatch_role_arn = "arn:aws:iam::111111111111:role/api-gateway-cloudwatch-role"
}
