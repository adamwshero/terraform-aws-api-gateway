module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.4.1"

  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = "REGIONAL"
  put_put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Custom Domain
  create_api_domain_name = true
  domain_names           = ["mydomain.something.com"]
  domain_certificate_arn = "arn:aws:acm:us-east-1:1111111111111:certificate/1aa11a11-a1a1-1a11-aaa1-1111aaaa1a1a"

  // API Resource Policy
  create_rest_api_policy = true
  rest_api_policy = templatefile("${get_terragrunt_dir()}/api_policy.json.tpl",
    {}
  )

  // API Definition & Vars
  openapi_definition = templatefile("${path.module}/openapi.yaml",
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
  access_log_format     = templatefile("${path.module}/log_format.json.tpl", {})
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
  method_settings = {
    "dev /*/*" = {
      metrics_enabled                            = true
      logging_level                              = "INFO"
      data_trace_enabled                         = true
      throttling_burst_limit                     = 100
      throttling_rate_limit                      = 100
      caching_enabled                            = true
      cache_ttl_in_seconds                       = 300
      cache_data_encrypted                       = true
      require_authorization_for_cache_control    = true
      unauthorized_cache_control_header_strategy = "FAIL_WITH_403"
    }
  }

  // Security
  enable_waf = true
  waf_acl    = "arn:aws:wafv2:us-east-1:111111111111:regional/webacl/my-app-nonprod/f111b1a1-1c11-1ea1-a111-cd1fe111b11a"

  // Execution Role
  cloudwatch_role_arn    = "arn:aws:iam::111111111111:role/my-app"
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
