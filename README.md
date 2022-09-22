[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)

![Terraform](https://cloudarmy.io/tldr/images/tf_aws.jpg)
<br>
<br>
<br>
<br>
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/adamwshero/terraform-aws-api-gateway?color=lightgreen&label=latest%20tag%3A&style=for-the-badge)
<br>
<br>
# [### BETA - LIMITED SUPPORT ###]  <br>
# terraform-aws-api-gateway (v1)


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

## Usage
  * The definition of the API is managed using the OpenAPI 3.x standard and is contained in a openapi.yaml file. This file contains the paths, authorization integrations, VPC Link integrations, responses, authorizers, etc. The goal is to configure as much of the API in this .yaml as possible and use Terragrunt to manage the broader context of API Gateway. This approach also reduces greatly the amount of Terraform resources that need to be created/managed.
  * The resources abstracted from Terraform and into OpenAPI spec are listed below. Because of this, there are no inputs in Terraform for the REST API itself except for the `name`, `description`, `body`, and `put_rest_api_mode`. To provide inputs for these resources, you must do so in the openapi.yaml file using the [AWS OpenAPI Extensions from the developer guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html).
    ```
    aws_api_gateway_resource
    aws_api_gateway_method
    aws_api_gateway_method_response
    aws_api_gateway_method_settings
    aws_api_gateway_integration
    aws_api_gateway_integration_response
    aws_api_gateway_gateway_response
    aws_api_gateway_model
    ```
  
  * The API is deployed every time a change is made in Terraform. This is done to ensure that the deploy being used matches with the most recent deploy. Otherwise, this can be unexpectedly out-of-sync.
  * This module was initially built to suit a public REST API over Private Link and as such, depended on a Network Load Balancer (NLB) to function with VPC Link. You can choose to remove this dependency for private API's not using the `regional` or `edge` deployment type.

## Special Notes 
  * (Merge Mode)
    * When importing Open API Specifications with the `body` argument, by default the API Gateway REST API will be replaced with the Open API Specification thus removing any existing methods, resources, integrations, or endpoints. Endpoint mutations are asynchronous operations, and race conditions with DNS are possible. To overcome this limitation, use the `put_rest_api_mode` attribute and set it to `merge`.
    * Using `put_rest_api_mode` = `merge` when importing the OpenAPI Specification, the AWS control plane will not delete all existing literal properties that are not explicitly set in the OpenAPI definition. Impacted API Gateway properties: ApiKeySourceType, BinaryMediaTypes, Description, EndpointConfiguration, MinimumCompressionSize, Name, Policy).
  * (PRIVATE Type API Endpoint)
    * When a REST API type of `PRIVATE` is needed, the VPC endpoints must be specified in the `openapi.yaml` definition. This is especially called out since it is not obvious as most modules allow setting this in the Terraform input block.
      ```
        x-amazon-apigateway-endpoint-configuration:
          vpcEndpointIds: [""]
          disableExecuteApiEndpoint: true
      ```
  * (Deployments History vs. Deployment being used)
    * We deploy every time using `(timestamp()}` in the `aws_api_gateway_deployment` resource. If we do not, sometimes the 
    deployment history has new deployments but the actual deployment in-use by the stage might be an older one.
<br>

## Open Issues
  * Canary
    * If enabled, the configured canary will prevent the next deploy. Canary has to be deleted for a deploy to happen again.

## Upcoming Improvements
  * Want `aws_api_gateway_method_settings` to allow us to apply different method settings by stage and by method instead of choosing between the full override `*/*` or only a single method to manage (e.g. `{resource_path}/{http_method}`). Currently whatever the path is dictates all method settings for the stages that have been deployed. Method settings would be represented as a `map` just as we already do with api keys and usage plans.
  * Want a usage_plan to accept many API keys as a `list(string)`. Currenly a usage plan has a 1:1 relationship with API keys. This should be expanded so that many API keys can be associated with a single usage plan in the event multiple external consumers have similar API needs. This will reduce the number of usage plans needed.
  * Want the ability to create/enable VPC Link in this module since we're already consuming the Network Load Balancer (NLB) outputs when we are using the `regional` or `edge` deployment type.

## The More You Know
  * CloudWatch Alarms
    * For CloudWatch Cache Hit/Miss alarms to work, you must enable the cache cluster for the stage.
  * NLB Health Checks
    * Ensure you are using the same availability zones from your NLB all the way to the target ALB where your service is running. Otherwise, you will see NLB targets (which are VPC endpint IP's) that are in an unhealthy state.

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
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.3"
}

inputs = {
  api_name          = "${local.prefix}-${local.product}-my-app-${local.env}"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_rest_api_mode = "merge"

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      apikey_name       = "${local.prefix}-${local.product}-${local.env}"
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
| [aws_api_gateway_rest_api.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_deployment.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_stage.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_method_settings.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_account.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_api_gateway_api_key.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_api_key) | resource |
| [aws_api_gateway_usage_plan.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_usage_plan_key.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan_key) | resource |
| [aws_cloudwatch_log_group.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_wafv2_web_acl_association.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

<br>


## Available Inputs

| Name                        | Resource                          | Variable                                     | Data Type         | Default                        | Required?
| --------------------------- | --------------------------------- | -------------------------------------------- | ----------------- | ------------------------------ | -------- |
| REST API Name               | `aws_api_gateway_rest_api`        | `api_name`                                   | `string`          | `null`                         | Yes      |
| REST API Description        | `aws_api_gateway_rest_api`        | `description`                                | `string`          | `null`                         | No       |
| OpenAPI Definition          | `aws_api_gateway_rest_api`        | `openapi_definition`                         | `string`          | `null`                         | Yes      |
| REST API PUT Mode           | `aws_api_gateway_rest_api`        | `put_rest_api_mode`                          | `string`          | `overwrite`                    | Yes      |
| REST API Endpoint Type      | `aws_api_gateway_rest_api`        | `endpoint_type`                              | `list(string)`    | `[ "EDGE" ]`                   | Yes      |
| Stage Name                  | `aws_api_gateway_stage`           | `stage_names`                                | `string`          | `null`                         | Yes      |
| Stage Description           | `aws_api_gateway_stage`           | `stage_description`                          | `string`          | `null`                         | No       |
| Stage Documentation Version | `aws_api_gateway_stage`           | `documentation_version`                      | `string`          | `null`                         | No       |
| Cache Cluster Enabled       | `aws_api_gateway_stage`           | `cache_cluster_enabled`                      | `bool`            | `true`                         | No       |
| Cache Cluster Size          | `aws_api_gateway_stage`           | `cache_cluster_size`                         | `number`          | `0.5`                          | No       |
| Enable Canary               | `aws_api_gateway_stage`           | `enable_canary`                              | `bool`            | `false`                        | No       |
| Percent of Traffic          | `aws_api_gateway_stage`           | `percent_traffic`                            | `number`          | `null`                         | No       |
| Stage Variable Overrides    | `aws_api_gateway_stage`           | `stage_variable_overrides`                   | `any`             | `{}`                           | No       |
| Use Stage Cache             | `aws_api_gateway_stage`           | `use_stage_cache`                            | `bool`            | `false`                        | No       |
| Client Certficicate Id      | `aws_api_gateway_stage`           | `client_certificate_id`                      | `string`          | `null`                         | No       |
| Stage Variables             | `aws_api_gateway_stage`           | `stage_variables`                            | `any`             | `{}`                           | No       |
| Xray Tracing Enabled        | `aws_api_gateway_stage`           | `xray_tracing_enabled`                       | `bool`            | `false`                        | No       |
| Access Log Format           | `aws_api_gateway_stage`           | `access_log_format`                          | `string`          | `null`                         | Yes      |
| Method Path                 | `aws_api_gateway_method_settings` | `method_path`                                | `string`          | `null`                         | Yes      |
| Metrics Enabled             | `aws_api_gateway_method_settings` | `metrics_enabled`                            | `bool`            | `true`                         | No       |
| Logging Level               | `aws_api_gateway_method_settings` | `logging_level`                              | `string`          | `INFO`                         | No       |
| Data Trace Enabled          | `aws_api_gateway_method_settings` | `data_trace_enabled`                         | `bool`            | `false`                        | No       |
| Throttling Burst Limit      | `aws_api_gateway_method_settings` | `throttling_burst_limit`                     | `number`          | `-1`                           | No       |
| Throttling Rate Limit       | `aws_api_gateway_method_settings` | `throttling_rate_limit`                      | `number`          | `-1`                           | No       |
| Caching Enabled             | `aws_api_gateway_method_settings` | `caching_enabled`                            | `bool`            | `true`                         | No       |
| Cache TTL in Seconds        | `aws_api_gateway_method_settings` | `cache_ttl_in_seconds`                       | `number`          | `300`                          | No       |
| Cache Data Encrypted        | `aws_api_gateway_method_settings` | `cache_data_encrypted`                       | `bool`            | `false`                        | No       |
| Require Cache Control Auth  | `aws_api_gateway_method_settings` | `require_authorization_for_cache_control`    | `bool`            | `true`                         | No       |
| Unauthorized Cache Strategy | `aws_api_gateway_method_settings` | `unauthorized_cache_control_header_strategy` | `string`          | `SUCCEED_WITH_RESPONSE_HEADER` | Yes      |
| Enable API Key              | `aws_api_gateway_api_key`         | `enable_api_key`                             | `bool`            | `true`                         | No       |
| API Key Name                | `aws_api_gateway_api_key`         | `api_key_name`                               | `string`          | `null`                         | Yes      |
| API Key Description         | `aws_api_gateway_api_key`         | `api_key_description`                        | `string`          | `null`                         | No       |
| Create Usage Plan           | `aws_api_gateway_usage_plan`      | `create_usage_plan`                          | `bool`            | `false`                        | No       |
| Usage Plan Map              | `aws_api_gateway_usage_plan`      | `usage_plans`                                | `list(object({})` | `null`                         | No       |
| API Keys                    | `aws_api_gateway_usage_plan`      | `api_keys`                                   | `list(object({})` | `null`                         | No       |
| Client Name                 | `aws_api_gateway_usage_plan`      | `client_name`                                | `string`          | `null`                         | No       |
| Request Limit               | `aws_api_gateway_usage_plan`      | `limit`                                      | `number`          | `20`                           | No       |
| Limit Offset                | `aws_api_gateway_usage_plan`      | `offset`                                     | `number`          | `2`                            | No       |
| Limit Period                | `aws_api_gateway_usage_plan`      | `period`                                     | `string`          | `WEEK`                         | No       |
| Burst Limit                 | `aws_api_gateway_usage_plan`      | `burst_limit`                                | `number`          | `5`                            | No       |
| Rate Limit                  | `aws_api_gateway_usage_plan`      | `rate_limit`                                 | `number`          | `10`                           | No       |
| CloudWatch Role Arn         | `aws_api_gateway_account`         | `cloudwatch_role_arn`                        | `string`          | `null`                         | No       |
| Log Group Name              | `aws_cloudwatch_log_group`        | `log_group_name`                             | `string`          | `null`                         | No       |
| Log Group Retention In Days | `aws_cloudwatch_log_group`        | `log_group_retention_in_days`                | `number`          | `7`                            | No       |
| Log Group KMS Key           | `aws_cloudwatch_log_group`        | `log_group_kms_key`                          | `string`          | `null`                         | No       |
| Enable WAF                  | `aws_wafv2_web_acl_association`   | `enable_waf`                                 | `bool`            | `false`                        | No       |
| WAF ACL                     | `aws_wafv2_web_acl_association`   | `waf_acl`                                    | `string`          | `null`                         | No       |

<br>

## Predetermined Inputs

| Name                        | Resource                          | Property                | Data Type         | Default                                           | Required?
| --------------------------- | --------------------------------- | ----------------------- | ----------------- | ------------------------------------------------- | -------- |
| REST API Id                 | `aws_api_gateway_deployment`      | `rest_api_id`           | `string`          | `aws_api_gateway_rest_api.this.id`                | Yes      |
| Stage Name                  | `aws_api_gateway_deployment`      | `stage_name`            | `string`          | `aws_api_gateway_method_settings.this.stage_name` | Yes      |
| REST API Id                 | `aws_api_gateway_stage`           | `rest_api_id`           | `string`          | `aws_api_gateway_rest_api.this.id`                | Yes      |
| Deployment Id               | `aws_api_gateway_stage`           | `deployment_id`         | `string`          | `aws_api_gateway_deployment.this.id`              | Yes      |
| Destination Arn             | `aws_api_gateway_stage`           | `destination_arn`       | `string`          | `aws_cloudwatch_log_group.this.arn`               | Yes      |
| REST API ID                 | `aws_api_gateway_method_settings` | `rest_api_id`           | `string`          | `aws_api_gateway_rest_api.this.id`                | Yes      |
| REST API ID                 | `aws_api_gateway_usage_plan`      | `api_id`                | `string`          | `aws_api_gateway_rest_api.this.id`                | Yes      |
| Key ID                      | `aws_api_gateway_usage_plan_key`  | `key_id`                | `string`          | `aws_api_gateway_api_key.this.id`                 | Yes      |
| Usage Plan ID               | `aws_api_gateway_usage_plan_key`  | `usage_plan_id`         | `string`          | `aws_api_gateway_usage_plan_key.this.id`          | Yes      |
| Resource Arn                | `aws_wafv2_web_acl_association`   | `resource_arn`          | `string`          | `aws_api_gateway_stage.this.arn`                  | Yes      |

<br>

## Outputs

| Name                                     | Description                              |
|------------------------------------------|------------------------------------------|
| api_gateway_rest_api_arn                 | Arn of the REST API.                     |
| api_gateway_rest_api_name                | Name of the REST API.                    |
| api_gateway_rest_api_id                  | Id of the REST API.                      |
| api_gateway_rest_api_execution_arn       | Execution Arn of the REST API.           |
| api_gateway_rest_api_stage_arn           | Arn of the deployed stage(s).            |
| api_gateway_rest_api_stage_id            | Id of the deployed stage(s).             |
| api_gateway_rest_api_stage_invoke_url    | Invoke URL of the deployed stage(s).     |
| api_gateway_rest_api_stage_execution_arn | Execution arn of the deployed stage(s).  |
| api_gateway_rest_api_stage_web_acl       | WAF Access Control List for the stage(s) |

<br>

## Supporting Articles & Documentation
  - Working with AWS API Gateway Extensions to OpenAPI
    - https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html
  - AWS API Gateway Dimensions & Metrics
    - https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-metrics-and-dimensions.html
  - OpenAPI Specification
    - https://github.com/OAI/OpenAPI-Specification
    - https://spec.openapis.org/oas/v3.1.0#openapi-specification
    - https://swagger.io/docs/specification/about/
