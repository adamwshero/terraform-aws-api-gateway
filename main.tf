resource "aws_api_gateway_rest_api" "this" {
  name              = var.api_name
  description       = var.description
  put_rest_api_mode = var.put_rest_api_mode
  body              = var.openapi_definition
  tags              = var.tags

  endpoint_configuration {
    types = [ var.endpoint_type ]
  }
}

resource "aws_api_gateway_deployment" "this" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  description = "Managed by Terraform"
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.

    #       We can use this method if we want to isolate deploys to a specific
    #       resource or resource attribute. But for now we just deploy every time
    #       with {timestamp()}.
    #       https://github.com/hashicorp/terraform-provider-aws/issues/162

    # redeployment = sha1(jsonencode([
    #   aws_api_gateway_rest_api.this.body,
    #   try(aws_api_gateway_rest_api_policy.this[0].id, null)
    #   ]
    # ))

    # We deploy the API every time Terraform is applied instead of using the
    # above method of only applying when the body of the openapi.yaml is
    # updated.
    redeployment = "${timestamp()}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count = length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id           = aws_api_gateway_rest_api.this.id
  stage_name            = var.stage_names[count.index]
  description           = "${var.stage_description} - Deployed on ${timestamp()}"
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
    for_each = var.enable_canary == true ? [true] : []

    content {
      percent_traffic          = var.percent_traffic
      stage_variable_overrides = var.stage_variable_overrides
      use_stage_cache          = var.use_stage_cache
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_api_gateway_method_settings" "this" {
  for_each = var.method_settings

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = element(split(" ", each.key), 0)

  # Extract method path after the stage name, formatted correctly
  method_path = join("/", slice(split(" ", each.key), 1, length(split(" ", each.key))))

  dynamic "settings" {
    for_each = length(var.method_settings) > 0 ? [true] : []
    content {
      metrics_enabled                            = lookup(each.value, "metrics_enabled", false)
      logging_level                              = lookup(each.value, "logging_level", "OFF")
      data_trace_enabled                         = lookup(each.value, "data_trace_enabled", false)
      throttling_burst_limit                     = lookup(each.value, "throttling_burst_limit", 0)
      throttling_rate_limit                      = lookup(each.value, "throttling_rate_limit", 0)
      caching_enabled                            = lookup(each.value, "caching_enabled", false)
      cache_ttl_in_seconds                       = lookup(each.value, "cache_ttl_in_seconds", 0)
      cache_data_encrypted                       = lookup(each.value, "cache_data_encrypted", false)
      require_authorization_for_cache_control    = lookup(each.value, "require_authorization_for_cache_control", false)
      unauthorized_cache_control_header_strategy = lookup(each.value, "unauthorized_cache_control_header_strategy", "FAIL_WITH_403")
    }
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
  depends_on = [
    aws_api_gateway_stage.this
  ]
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

# EXISTING custom domain name
resource "aws_api_gateway_base_path_mapping" "existing" {
  count = !var.create_api_domain_name && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = var.domain_names[count.index]
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  base_path   = var.domain_base_path
}

# REGIONAL ACM custom domain name
resource "aws_api_gateway_domain_name" "regional_acm" {
  count = var.create_api_domain_name && var.endpoint_type == "REGIONAL" && var.certificate_type == "ACM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  domain_name = var.domain_names[count.index]
  regional_certificate_arn = var.domain_certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  dynamic "mutual_tls_authentication" {
    for_each = length(keys(var.mutual_tls_authentication)) == 0 ? [] : [var.mutual_tls_authentication]

    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = try(mutual_tls_authentication.value.truststore_version, null)
    }
  }
}

resource "aws_api_gateway_base_path_mapping" "regional_acm" {
  count = var.create_api_domain_name && var.endpoint_type == "REGIONAL" && var.certificate_type == "ACM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.regional_acm[count.index].id
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  base_path   = var.domain_base_path
}

# REGIONAL IAM custom domain name
resource "aws_api_gateway_domain_name" "regional_iam" {
  count = var.create_api_domain_name && var.endpoint_type == "REGIONAL" && var.certificate_type == "IAM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  domain_name = var.domain_names[count.index]

  regional_certificate_name = var.domain_certificate_name
  certificate_body          = var.iam_certificate_body
  certificate_chain         = var.iam_certificate_chain
  certificate_private_key   = var.iam_certificate_private_key

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  dynamic "mutual_tls_authentication" {
    for_each = length(keys(var.mutual_tls_authentication)) == 0 ? [] : [var.mutual_tls_authentication]

    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = try(mutual_tls_authentication.value.truststore_version, null)
    }
  }
}

resource "aws_api_gateway_base_path_mapping" "regional_iam" {
  count = var.create_api_domain_name && var.endpoint_type == "REGIONAL" && var.certificate_type == "IAM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.regional_iam[count.index].id
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  base_path   = var.domain_base_path
}

# EDGE ACM custom domain name
resource "aws_api_gateway_domain_name" "edge_acm" {
  count = var.create_api_domain_name && var.endpoint_type == "EDGE" && var.certificate_type == "ACM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  domain_name = var.domain_names[count.index]

  certificate_arn = var.domain_certificate_arn

  endpoint_configuration {
    types = ["EDGE"]
  }

  dynamic "mutual_tls_authentication" {
    for_each = length(keys(var.mutual_tls_authentication)) == 0 ? [] : [var.mutual_tls_authentication]

    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = try(mutual_tls_authentication.value.truststore_version, null)
    }
  }
}

resource "aws_api_gateway_base_path_mapping" "edge_acm" {
  count = var.create_api_domain_name && var.endpoint_type == "EDGE" && var.certificate_type == "ACM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.edge_acm[count.index].id
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  base_path   = var.domain_base_path
}

# EDGE IAM custom domain name
resource "aws_api_gateway_domain_name" "edge_iam" {
  count = var.create_api_domain_name && var.endpoint_type == "EDGE" && var.certificate_type == "IAM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  domain_name = var.domain_names[count.index]

  certificate_name          = var.domain_certificate_name
  certificate_body          = var.iam_certificate_body
  certificate_chain         = var.iam_certificate_chain
  certificate_private_key   = var.iam_certificate_private_key

  endpoint_configuration {
    types = ["EDGE"]
  }

  dynamic "mutual_tls_authentication" {
    for_each = length(keys(var.mutual_tls_authentication)) == 0 ? [] : [var.mutual_tls_authentication]

    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = try(mutual_tls_authentication.value.truststore_version, null)
    }
  }
}

resource "aws_api_gateway_base_path_mapping" "edge_iam" {
  count = var.create_api_domain_name && var.endpoint_type == "EDGE" && var.certificate_type == "IAM" && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  api_id      = aws_api_gateway_rest_api.this.id
  domain_name = aws_api_gateway_domain_name.edge_iam[count.index].id
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  base_path   = var.domain_base_path
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count = var.create_rest_api_policy && length(var.stage_names) > 0 ? length(var.stage_names) : 0

  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = var.rest_api_policy
}

resource "aws_api_gateway_model" "this" {
  for_each = var.models
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = each.key
  description  = lookup(each.value,"description","")
  content_type = lookup(each.value,"content_type","")
  schema = lookup(each.value,"schema",{})
}
