[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)

![Terraform](https://cloudarmy.io/tldr/images/tf_aws.jpg)
<br>
<br>
<br>
<br>
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/adamwshero/terraform-aws-api-gateway?color=lightgreen&label=latest%20tag%3A&style=for-the-badge)
<br>
<br>
# terraform-aws-api-gateway (v1) [### BETA ###]

Terraform module to create [Amazon API Gateway (v1)](https://aws.amazon.com/api-gateway/) resources.

Amazon API Gateway is a fully managed service that makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale. APIs act as the "front door" for applications to access data, business logic, or functionality from your backend services. Using API Gateway, you can create RESTful APIs and WebSocket APIs that enable real-time two-way communication applications. API Gateway supports containerized and serverless workloads, as well as web applications.
<br>

Build RESTful APIs optimized for serverless workloads and HTTP backends using HTTP APIs. HTTP APIs are the best choice for building APIs that only require API proxy functionality. If your APIs require API proxy functionality and API management features in a single solution, API Gateway also offers REST APIs.
<br>

## Assumptions
  * Public API Only
    * You already have Network Load Balancer (NLB) with an IP type target group created if you are creating an API using the `regional` or `edge` deployment type.
    * You already have VPC Link setup and configured to point to your internal Network Load Balancer (NLB) if you are creating an API using the `regional` or `edge` deployment type.
    * You have already configured a VPC endpoint(s) that your NLB is using as targets if you are creating an API using the `regional` or `edge` deployment type. That VPC endpoint is connected to a VPC Endpoint Service in the same account or another account. (see architecture diagram)
  * All Scenarios
    * You already have created the CloudWatch Log Group for your access logging. This is different from execution log groups which is created automatically by API Gateway and is not manageable by Terraform.
    * You already have created the IAM role and policy for API Gateway execution. This role is needed so that it can create the CloudWatch Log Group and push log streams to it.
<br>

## Usage
  * The definition of the API is managed using the OpenAPI 3.x standard and is contained in a openapi.yaml file. This file contains the paths, authorization integrations, VPC Link integrations, responses, authorizers, etc. The goal is to configure as much of the API in this .yaml as possible and use Terragrunt to manage the broader context of API Gateway. This approach also reduces greatly the amount of Terraform resources that need to be created/managed.
  * The API is deployed every time a change is made in Terraform. This is done to ensure that the deploy being used matches with the most recent deploy. Otherwise, this can be unexpectedly out-of-sync.
  * This module was initially built to suit a public REST API over Private Link and as such, depended on a Network Load Balancer (NLB) to function with VPC Link. You can choose to remove this dependency for private API's not using the `regional` or `edge` deployment type.
<br>

## Open Issues
  - Canary
    * If enabled, the configured canary will prevent the next deploy. Canary has to be deleted for a deploy to happen again.
  - Deployments History vs. Deployment being used
    * We deploy every time using `(timestamp()}` in the `aws_api_gateway_deployment` resource. If we do not, sometimes the 
    deployment history has new deployments but the actual deployment in-use by the stage might be an older one.
<br>

## Improvements Needed
  - Need `aws_api_gateway_method_settings` to allow us to apply different method settings by stage and by method instead of choosing between the full override `*/*` or only a single method to manage (e.g. `{resource_path}/{http_method}`). Currently whatever the path is dictates all method settings for the stages that have been deployed. Method settings would be represented as a `map` just as we already do with api keys and usage plans.
  - Need usage_plan to accept many API keys as a `list(string)`. Currenly a usage plan has a 1:1 relationship with API keys. This should be expanded so that many API keys can be associated with a single usage plan in the event multiple external consumers have similar API needs. This will reduce the number of usage plans needed.
  - Need the ability to create/enable VPC Link in this module since we're already consuming the Network Load Balancer (NLB) outputs when we are using the `regional` or `edge` deployment type.
<br>

## Helpful Information
  - CloudWatch Alarms
    * For CloudWatch Cache Hit/Miss alarms to work, you must enable the cache cluster for the stage.
  - NLB Health Checks
    * Ensure you are using the same availability zones from your NLB all the way to the target ALB where your service is running. Otherwise, you will see NLB targets (which are VPC endpint IP's) that are in an unhealthy state.
<br>

### Terragrunt Complete Example
```
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.67.0 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.0 
| <a name="requirement_terragrunt"></a> [terragrunt](#requirement\_terragrunt) | >= 0.28.0 |

<br>


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.30.0 |

<br>

## Resources

| Name | Type |
|------|------|
| [api_gateway_rest_api.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [api_gateway_deployment.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [api_gateway_stage.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [api_gateway_method_settings.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_wafv2_web_acl_association.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

<br>


## Available Inputs

| API Gateway Property  | Variable                  | Data Type   |
| ----------------------| --------------------------| ------------|
| None                  | `     `                   | String      |

<br>


## Outputs

| Name                         | Description                                 |
|------------------------------|---------------------------------------------|
| api_gateway_arn              | Arn of the REST API                         |
| api_gateway_execution_arn    | Arn of the REST API execution role          |
| api_gateway_id               | Id of the REST API                          |
