locals {
  external_deps = read_terragrunt_config(find_in_parent_folders("external-deps.hcl"))
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  product_vars  = read_terragrunt_config(find_in_parent_folders("product.hcl"))
  env_vars      = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  product       = local.product_vars.locals.product_name
  prefix        = local.product_vars.locals.prefix
  account       = local.account_vars.locals.account_id
  env           = local.env_vars.locals.env

  name = "${local.prefix}-${local.product}-${local.env}" // Keeping it DRY

  tags = merge(
    local.env_vars.locals.tags,
    local.additional_tags
  )

  additional_tags = {
  }
}

include {
  path = find_in_parent_folders()
}

dependency "waf_acl" {
  config_path = "../../../core/waf"
}

dependency "execution_role" {
  config_path = "../../../core/iam/roles/apigw-execution"
}

dependency "execution_policy" {
  config_path = "../../../core/iam/policies/apigw-execution"
}

terraform {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.0"
}

inputs = {
  api_name          = "${local.prefix}-${local.product}-my-app-${local.env}"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_rest_api_mode = "merge"

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      apikey_name       = local.name
      endpoint_uri      = "http://${dependency.internal_nlb.outputs.lb_dns_name}/my_app/"
      vpc_link_id       = "abc1d3o"
      lambda_invoke_arn = dependency.lambda_authorizer.outputs.lambda_function_invoke_arn
    }
  )

  // Stage Settings
  stage_names           = ["${local.env}"]
  stage_description     = "Development stage for My App API"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
  xray_tracing_enabled  = false
  log_group_name        = "/aws/apigateway/access/${local.prefix}-${local.product}/my_app/${local.env}"
  access_log_format     = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})
  // Canary Stage Settings
  use_stage_cache = false
  percent_traffic = 0
  stage_variable_overrides = {
    stage_description     = "Canary Development stage for My App API"
    cache_cluster_enabled = false
    cache_cluster_size    = 0.5
    xray_tracing_enabled  = false
  }

  // Method Settings
  method_path                                = "*/*" // {resource_path}/{http_method}
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
  waf_acl    = dependency.waf_acl.outputs.web_acl_arn

  // Execution Role
  cloudwatch_role_arn    = dependency.execution_role.outputs.iam_role_arn
  cloudwatch_policy_name = dependency.execution_policy.outputs.name

  // Usage Plans & API Keys
  create_usage_plan = true
  enable_api_key    = true
  api_keys = [
    {
      name       = "open-use-internal-${local.env}"
      key_type   = "API_KEY"
      usage_plan = "open-use-internal-${local.env}"
    },
    {
      name       = "external-partner-${local.env}"
      key_type   = "API_KEY"
      usage_plan = "external-partner-daily-throttle-${local.env}"
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
      stages       = ["${local.env}"]
    },
    {
      name         = "external-partner-daily-throttle-${local.env}"
      description  = "Daily throttled API Usage Plan."
      burst_limit  = 300
      rate_limit   = 600
      quota_limit  = 15000
      quota_offset = 0
      quota_period = "DAY",
      stages       = ["${local.env}"]
    }
  ]

  tags = local.tags
}
