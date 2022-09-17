resource "aws_api_gateway_rest_api" "this" {
  name              = var.api_name
  description       = var.description
  put_rest_api_mode = var.put_rest_api_mode
  body              = var.openapi_definition

  endpoint_configuration {
    types = var.endpoint_type
    # vpc_endpoint_ids = var.vpc_endpoint_ids
  }
}

resource "time_static" "deploy" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_deployment.this[count.index].id
      ]
    ))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "this" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_method_settings.this[count.index].stage_name
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body
      ]
    ))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id           = aws_api_gateway_rest_api.this.id
  stage_name            = element(var.stage_names, count.index)
  description           = var.stage_description
  documentation_version = var.documentation_version
  deployment_id         = aws_api_gateway_deployment.this[count.index].id
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_size
  client_certificate_id = var.client_certificate_id
  variables             = var.stage_variables
  xray_tracing_enabled  = var.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = aws_cloudwatch_log_group.this.arn != null && var.access_log_format != null ? [true] : []

    content {
      destination_arn = aws_cloudwatch_log_group.this.arn
      format          = var.access_log_format
    }
  }
  dynamic "canary_settings" {
    for_each = var.stage_variable_overrides != null ? [true] : []

    content {
      percent_traffic          = var.percent_traffic
      stage_variable_overrides = var.stage_variable_overrides
      use_stage_cache          = var.use_stage_cache
    }
  }
}

resource "aws_api_gateway_method_settings" "this" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = element(var.stage_names, count.index)
  method_path = var.method_path
  settings {
    metrics_enabled                            = var.metrics_enabled
    logging_level                              = var.logging_level
    data_trace_enabled                         = var.data_trace_enabled
    throttling_burst_limit                     = var.throttling_burst_limit
    throttling_rate_limit                      = var.throttling_rate_limit
    caching_enabled                            = var.caching_enabled
    cache_ttl_in_seconds                       = var.cache_ttl_in_seconds
    cache_data_encrypted                       = var.cache_data_encrypted
    require_authorization_for_cache_control    = var.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.unauthorized_cache_control_header_strategy
  }
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}
resource "aws_api_gateway_api_key" "this" {
  for_each = {
    for key in var.api_keys : key.name => {
      name = key.name
    }
    if var.create_usage_plan == true && var.enable_api_key == true && length(var.stage_names) > 0
  }
  enabled = var.enable_api_key
  name    = each.value.name
}

resource "aws_api_gateway_usage_plan" "this" {
  for_each = {
    for key in var.usage_plans : key.name => {
      name         = key.name
      description  = key.description
      burst_limit  = key.burst_limit
      rate_limit   = key.rate_limit
      quota_limit  = key.quota_limit
      quota_offset = key.quota_offset
      quota_period = key.quota_period
      stages       = key.stages
    }
    if var.create_usage_plan == true && length(var.stage_names) > 0
  }

  name        = var.client_name == null ? "${each.value.name}" : "${each.value.name}"
  description = var.client_name == null ? "${each.value.description}" : "${each.value.description} for ${var.client_name}."
  dynamic "api_stages" {
    for_each = each.value.stages
    content {
      api_id = aws_api_gateway_rest_api.this.id
      stage  = api_stages.value
    }
    # throttle {
    #   for_each = each.value.paths
    #     path = api_stages.throttle.value.paths
    #   burst_limit = each.value.api_stages.throttle["burst_limit"]
    #   rate_limit = each.value.api_stages.throttle["rate_limit"]
    # }
  }
  quota_settings {
    limit  = each.value.quota_limit
    offset = each.value.quota_offset
    period = each.value.quota_period
  }
  throttle_settings {
    burst_limit = each.value.burst_limit
    rate_limit  = each.value.rate_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = {
    for key in var.api_keys : key.name => {
      name       = key.name
      key_type   = key.key_type
      usage_plan = key.usage_plan
    }
    if var.create_usage_plan == true && length(var.stage_names) > 0
  }

  key_id        = aws_api_gateway_api_key.this[each.key].id
  key_type      = each.value.key_type
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan].id
  depends_on = [
    aws_api_gateway_api_key.this,
    aws_api_gateway_usage_plan.this,
  ]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable_waf != false && length(var.stage_names) > 0 ? length(var.stage_names) : 0
  resource_arn = aws_api_gateway_stage.this[count.index].arn
  web_acl_arn  = var.waf_acl
}
