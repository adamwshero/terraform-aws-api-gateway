### Terraform Basic Example + Lambda (as authorizer)
```
module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"


inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      endpoint_uri             = "https://my-app.nonprod.company.com}/my_app_path"
      authorizer_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:111111111111:function:my-app-dev/invocation"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-app-dev"
    }
  )

  // Stage Settings
  stage_names           = ["dev"]
  stage_description     = "Development stage for My App API"
  log_group_name        = "/aws/apigateway/access/my_app/dev"
  access_log_format     = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})

  // Method Settings
  method_path = "*/*"

  // Security
  enable_waf = false

  // Execution Role
  cloudwatch_role_arn    = "arn:aws:logs:us-east-1:111111111111:log-group:/aws/lambda/my-app-dev"
  cloudwatch_policy_name = "my-app-dev"

  // Usage Plans & API Keys
  create_usage_plan = false
  enable_api_key    = false

  tags = local.tags
}
```
### Terraform Example + Lambda (as authorizer) + Stage Canary + Method Settings
```
module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"


inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      endpoint_uri             = "https://my-app.nonprod.company.com/my_app_path"
      vpc_link_id              = "9ab12c"
      authorizer_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:111111111111:function:my-app-dev/invocation"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-app-dev"
    }
  )

  // Stage Settings
  stage_names           = ["dev"]
  stage_description     = "Development stage for My App API"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
  xray_tracing_enabled  = false
  log_group_name        = "/aws/apigateway/access/my_app/dev"
  access_log_format     = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})
  // Canary Stage Settings
  enable_canary   = false
  use_stage_cache = false
  percent_traffic = 0
  stage_variable_overrides = {
    stage_description     = "Canary Development stage for My App API"
    cache_cluster_enabled = false
    cache_cluster_size    = 0.5
    xray_tracing_enabled  = false
  }

  // Method Settings
  method_path                                = "*/*"
  metrics_enabled                            = true
  data_trace_enabled                         = true
  log_level                                  = "INFO"
  throttling_burst_limit                     = 5000
  throttling_rate_limit                      = 10000
  caching_enabled                            = true
  cache_data_encrypted                       = false
  cache_ttl_in_seconds                       = 300
  require_authorization_for_cache_control    = true
  unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"

  // Security
  enable_waf = false

  // Execution Role
  cloudwatch_role_arn    = "arn:aws:logs:us-east-1:111111111111:log-group:/aws/lambda/my-app-dev"
  cloudwatch_policy_name = "my-app-dev"

  // Usage Plans & API Keys
  create_usage_plan = false
  enable_api_key    = false

  tags = local.tags
}
```

### Terraform Complete Example + Lambda (as authorizer) + Stage Canary + Method Settings + WAF
```
module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"


inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      endpoint_uri             = "https://my-app.nonprod.company.com/my_app_path"
      vpc_link_id              = "9ab12c"
      authorizer_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:111111111111:function:my-app-dev/invocation"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-app-dev"
    }
  )

  // Stage Settings
  stage_names           = ["dev"]
  stage_description     = "Development stage for My App API"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
  xray_tracing_enabled  = false
  log_group_name        = "/aws/apigateway/access/my_app/dev"
  access_log_format     = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})
  // Canary Stage Settings
  enable_canary   = false
  use_stage_cache = false
  percent_traffic = 0
  stage_variable_overrides = {
    stage_description     = "Canary Development stage for My App API"
    cache_cluster_enabled = false
    cache_cluster_size    = 0.5
    xray_tracing_enabled  = false
  }

  // Method Settings
  method_path                                = "*/*"
  metrics_enabled                            = true
  data_trace_enabled                         = true
  log_level                                  = "INFO"
  throttling_burst_limit                     = 5000
  throttling_rate_limit                      = 10000
  caching_enabled                            = true
  cache_data_encrypted                       = false
  cache_ttl_in_seconds                       = 300
  require_authorization_for_cache_control    = true
  unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"

  // Security
  enable_waf = true
  waf_acl    = "arn:aws:wafv2:us-east-1:111111111111:regional/webacl/my-app-nonprod/f111b1a1-1c11-1ea1-a111-cd1fe111b11a"

  // Execution Role
  cloudwatch_role_arn    = "arn:aws:logs:us-east-1:111111111111:log-group:/aws/lambda/my-app-dev"
  cloudwatch_policy_name = "my-app-dev"

  // Usage Plans & API Keys
  create_usage_plan = false
  enable_api_key    = false

  tags = local.tags
}
```


### Terraform Complete Example + Lambda (as authorizer) + Stage Canary + Method Settings + WAF + API Keys + Usage Plans
```
module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"


inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      endpoint_uri             = "https://my-app.nonprod.company.com/my_app_path"
      vpc_link_id              = "9ab12c"
      authorizer_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:111111111111:function:my-app-dev/invocation"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-app-dev"
    }
  )

  // Stage Settings
  stage_names           = ["dev"]
  stage_description     = "Development stage for My App API"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
  xray_tracing_enabled  = false
  log_group_name        = "/aws/apigateway/access/my_app/dev"
  access_log_format     = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})
  // Canary Stage Settings
  enable_canary   = false
  use_stage_cache = false
  percent_traffic = 0
  stage_variable_overrides = {
    stage_description     = "Canary Development stage for My App API"
    cache_cluster_enabled = false
    cache_cluster_size    = 0.5
    xray_tracing_enabled  = false
  }

  // Method Settings
  method_path                                = "*/*"
  metrics_enabled                            = true
  data_trace_enabled                         = true
  log_level                                  = "INFO"
  throttling_burst_limit                     = 5000
  throttling_rate_limit                      = 10000
  caching_enabled                            = true
  cache_data_encrypted                       = false
  cache_ttl_in_seconds                       = 300
  require_authorization_for_cache_control    = true
  unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"

  // Security
  enable_waf = true
  waf_acl    = "arn:aws:wafv2:us-east-1:111111111111:regional/webacl/my-app-nonprod/f111b1a1-1c11-1ea1-a111-cd1fe111b11a"

  // Execution Role
  cloudwatch_role_arn    = "arn:aws:logs:us-east-1:111111111111:log-group:/aws/lambda/my-app-dev"
  cloudwatch_policy_name = "my-app-dev"

  // Usage Plans & API Keys
  create_usage_plan = true
  enable_api_key    = true
  api_keys = [
    {
      name       = "open-use-internal-dev"
      key_type   = "API_KEY"
      usage_plan = "open-use-internal-dev"
    },
    {
      name       = "external-partner-dev"
      key_type   = "API_KEY"
      usage_plan = "external-partner-daily-throttle-dev"
    }
  ]
  usage_plans = [
    {
      name         = "open-use-internal-${local.env}"
      description  = "Open API Usage Plan."
      burst_limit  = 10000000
      rate_limit   = 10000000
      quota_limit  = 10000000
      quota_offset = 6
      quota_period = "WEEK"
      stages       = ["dev"]
    },
    {
      name         = "external-partner-daily-throttle-dev"
      description  = "Daily throttled API Usage Plan."
      burst_limit  = 300
      rate_limit   = 600
      quota_limit  = 15000
      quota_offset = 0
      quota_period = "DAY",
      stages       = ["dev"]
    }
  ]

  tags = local.tags
}
```