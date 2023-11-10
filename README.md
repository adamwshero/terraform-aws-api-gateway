[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://github.com/vshymanskyy/StandWithUkraine/blob/main/docs/README.md)

![Terraform](https://cloudarmy.io/tldr/images/tf_aws.jpg)
<br>
<br>
<br>
<br>
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/adamwshero/terraform-aws-api-gateway?color=lightgreen&label=latest%20tag%3A&style=for-the-badge)
<br>
<br>
# terraform-aws-api-gateway (V1)


Terraform module to create [Amazon API Gateway (v1)](https://aws.amazon.com/api-gateway/) resources.

Amazon API Gateway is a fully managed service that makes it easy for developers to create, publish, maintain, monitor, and secure APIs at any scale. APIs act as the "front door" for applications to access data, business logic, or functionality from your backend services. Using API Gateway, you can create RESTful APIs and WebSocket APIs that enable real-time two-way communication applications. API Gateway supports containerized and serverless workloads, as well as web applications.
<br>

Build RESTful APIs optimized for serverless workloads and HTTP backends using HTTP APIs. HTTP APIs are the best choice for building APIs that only require API proxy functionality. If your APIs require API proxy functionality and API management features in a single solution, API Gateway also offers REST APIs.
<br>

## Module Capabilities
  * Uses OpenAPI 3.x Specification
  * Deploy REST API to many stages
  * Supports creation of many API Keys
  * Supports creation of many stages
  * Supports stage canaries.
  * Supports assigning many API Keys to many usage plans
  * Supports assigning many usage plans to many stages
  * Supports WAF integration for stages
  * Supports VPC Link for `EDGE` & `REGIONAL` type API's
  * Supports VPC Endpoints for `PRIVATE` type API's
<br>

## Distributed Architecture Example
![](https://github.com/adamwshero/terraform-aws-api-gateway/blob/main/assets/public-api-distributed-model.png)

## Assumptions
  * Public API Scenario
    * You already have Network Load Balancer (NLB) with an IP type target group created if you are creating an API using the `regional` or `edge` deployment type.
    * You already have VPC Link setup and configured to point to your internal Network Load Balancer (NLB) if you are creating an API using the `regional` or `edge` deployment type.
    * You have already configured a VPC endpoint(s) that your NLB is using as targets if you are creating an API using the `regional` or `edge` deployment type. That VPC endpoint is connected to a VPC Endpoint Service in the same account or another account. (see architecture diagram)
  * All Scenarios
    * You already have created the CloudWatch Log Group for your access logging. This is different from execution log groups which is created automatically by API Gateway and is not manageable by Terraform.
    * You already have created the IAM role and policy for API Gateway execution. This role is needed so that it can create the CloudWatch Log Group and push log streams to it.
<br>

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
<br>

## Special Notes 
  * (Merge Mode)
    * When importing Open API Specifications with the `body` argument, by default the API Gateway REST API will be replaced with the Open API Specification thus removing any existing methods, resources, integrations, or endpoints. Endpoint mutations are asynchronous operations, and race conditions with DNS are possible. To overcome this limitation, use the `put_rest_api_mode` attribute and set it to `merge`.
    * Using `put_rest_api_mode` = `merge` when importing the OpenAPI Specification, the AWS control plane WILL NOT delete all existing literal properties that are not explicitly set in the OpenAPI definition. Impacted API Gateway properties: ApiKeySourceType, BinaryMediaTypes, Description, EndpointConfiguration, MinimumCompressionSize, Name, Policy).
    * When using `put_rest_api_mode` = `merge`, and you rename/remove a resource in the body, that resource change WILL NOT be reflected in the console.
    * When using `put_rest_api_mode` = `overwrite`, the AWS APIGW console reflects all changes you make accurately. However, be aware of the warning issued by the provider about using `overwrite` mode. We have not experienced issues using it so far with this module and implementation but in tests, we have only toggled this mode when we are renaming resource paths or removing resources from the body altogether.
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
    * Currently there is almost always one deployment, which is the most recent one. When there are multiple deployments in history, only the most recent will be used by default.
<br>

## Upcoming/Recent Improvements
  * Want `aws_api_gateway_method_settings` to allow us to apply different method settings by stage and by method instead of choosing between the full override `*/*` or only a single method to manage (e.g. `{resource_path}/{http_method}`). Currently whatever the path is dictates all method settings for the stages that have been deployed. Method settings would be represented as a `map` just as we already do with api keys and usage plans.
  * Want a usage_plan to accept many API keys as a `list(string)`. Currenly a usage plan has a 1:1 relationship with API keys. This should be expanded so that many API keys can be associated with a single usage plan in the event multiple external consumers have similar API needs. This will reduce the number of usage plans needed.
  * <s>Want the ability to create/enable VPC Link in this module since we're already consuming the Network Load Balancer (NLB) outputs when we are using the `regional` or `edge` deployment type</s>.
    * [Works well with our VPC Link module](https://registry.terraform.io/modules/adamwshero/api-gateway-vpc-link/aws/latest)

## The More You Know
  * CloudWatch Alarms
    * For CloudWatch Cache Hit/Miss alarms to work, you must enable the cache cluster for the stage.
  * NLB Health Checks
    * Ensure you are using the same availability zones from your NLB all the way to the target ALB where your service is running. Otherwise, you will see NLB targets (which are VPC endpint IP's) that are in an unhealthy state.
  * NLB Target Groups
    * At the time of this writing, there is an open issue for NLB's specifically where you will only be able to have 1 target group for a listener in Terraform (e.g. 443). Because of this, we must deploy an NLB, & VPCLink for each API instead of having 1 NLB and many target groups for each API. [See this issue opened for the AWS CDK (is not a CDK issue alone)](https://github.com/aws/aws-cdk/issues/11943)
  * VPCLink + Private Link
    * In the case where we are using private link + VPC Link to connect a REST API to a target service, it is important to know that the integration URI needed for the API integration request needs to match the domain/cert that is being used at the ALB level closest to the target service. Do not point the integration URI to the network load balancer. If the ALB listener for the application has a cert attached for `*.nonprod.mycompany.com`, the integration URI for the API needs to also use that domain `(e.g. my-app.nonprod.mycompany.com)` to avoid a cert mismatch error.
<br>

### Terraform Basic Example
```
module "rest-api" {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"


inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

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
### Terragrunt Basic Example
```
terraform {
  source = "git::git@github.com:adamwshero/terraform-aws-api-gateway.git//.?ref=1.0.7"
}

inputs = {
  api_name          = "my-app-dev"
  description       = "Development API for the My App service."
  endpoint_type     = ["REGIONAL"]
  put_rest_api_mode = "merge"   // Toggle to `overwrite` only when renaming a resource path or removing a resource from the openapi definition.

  // API Definition & Vars
  openapi_definition = templatefile("${get_terragrunt_dir()}/openapi.yaml",
    {
      endpoint_uri             = "https://my-app.nonprod.company.com}/my_app_path"
      authorizer_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:111111111111:function:my-app-dev/invocation"
      authorizer_execution_arn = "arn:aws:iam::111111111111:role/my-app-dev"
    }
  )

  // Stage Settings
  stage_names       = ["dev"]
  stage_description = "Development stage for My App API"
  log_group_name    = "/aws/apigateway/access/my_app/dev"
  access_log_format = templatefile("${get_terragrunt_dir()}/log_format.json.tpl", {})

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
