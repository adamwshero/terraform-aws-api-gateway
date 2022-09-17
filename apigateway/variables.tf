#####################
# REST API Variables
#####################
variable "api_name" {
  description = "(Required) Name of the REST API. If importing an OpenAPI specification via the `body` argument, this corresponds to the `info.title` field. If the argument value is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = string
  default     = null
}
variable "description" {
  description = "(Optional) Description of the REST API. If importing an OpenAPI specification via the `body` argument, this corresponds to the `info.description` field. If the argument value is provided and is different than the OpenAPI value, the argument value will override the OpenAPI value."
  type        = string
  default     = null
}

variable "openapi_definition" {
  description = "seomthing"
  type        = string
}

variable "put_rest_api_mode" {
  description = "test"
  type        = string
}

variable "endpoint_type" {
  description = "test"
  type        = list(string)
}

# variable "vpc_endpoint_ids" {
#   description = "test"
#   type        = list(any)
# }

#############################
# API Gateway Stage Settings
#############################
variable "stage_names" {
  description = "(Required) Name of the stage(s)."
  type        = list(string)
  default     = null
}

variable "stage_description" {
  description = "(Optional) Description of the stage."
  type        = string
  default     = null
}

variable "documentation_version" {
  description = "(Optional) Version of the associated API documentation."
  type        = string
  default     = null
}

variable "cache_cluster_enabled" {
  description = "(Optional) Whether a cache cluster is enabled for the stage."
  type        = bool
  default     = true
}

variable "cache_cluster_size" {
  description = "(Optional) Size of the cache cluster for the stage, if enabled. Allowed values include `0.5`, `1.6`, `6.1`, `13.5`, `28.4`, `58.2`, `118` and `237`."
  type        = number
  default     = 0.5
}

variable "percent_traffic" {
  description = "(Optional) Percent 0.0 - 100.0 of traffic to divert to the canary deployment."
  type        = number
  default     = null
}

variable "stage_variable_overrides" {
  description = "(Optional) Map of overridden stage variables (including new variables) for the canary deployment."
  type        = any
  default     = {}
}

variable "use_stage_cache" {
  description = "(Optional) Whether the canary deployment uses the stage cache. Defaults to false."
  type        = bool
  default     = false
}

variable "client_certificate_id" {
  description = "(Optional) Identifier of a client certificate for the stage."
  type        = string
  default     = null
}

variable "stage_variables" {
  description = "(Optional) Map that defines the stage variables."
  type        = any
  default     = {}
}

variable "xray_tracing_enabled" {
  description = "(Optional) Whether active tracing with X-ray is enabled. Defaults to false."
  type        = bool
  default     = false
}
variable "access_log_format" {
  description = "(Required) Formatting and values recorded in the logs. For more information on configuring the log format rules visit the AWS documentation"
  type        = string
}

########################################
# API Gateway Method Settings Variables
########################################
variable "method_path" {
  description = "(Required) Method path defined as `{resource_path}/{http_method}` for an individual method override, or `*/*` for overriding all methods in the stage. Ensure to trim any leading forward slashes in the path."
  type        = string
}

variable "metrics_enabled" {
  description = "(Optional) Whether Amazon CloudWatch metrics are enabled for this method."
  type        = string
  default     = true
}

variable "logging_level" {
  description = "(Optional) Logging level for this method, which effects the log entries pushed to Amazon CloudWatch Logs. The available levels are OFF, ERROR, and INFO."
  type        = string
  default     = "INFO"
}

variable "data_trace_enabled" {
  description = "(Optional) Whether data trace logging is enabled for this method, which effects the log entries pushed to Amazon CloudWatch Logs."
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "(Optional) Throttling burst limit. Default: -1 (throttling disabled)."
  type        = number
  default     = -1
}

variable "throttling_rate_limit" {
  description = "(Optional) Throttling rate limit. Default: -1 (throttling disabled)."
  type        = number
  default     = -1
}

variable "caching_enabled" {
  description = "(Optional) Whether responses should be cached and returned for requests. A cache cluster must be enabled on the stage for responses to be cached."
  type        = bool
  default     = true
}

variable "cache_ttl_in_seconds" {
  description = "(Optional) Time to live (TTL), in seconds, for cached responses. The higher the TTL, the longer the response will be cached."
  type        = number
  default     = 300
}

variable "cache_data_encrypted" {
  description = "(Optional) Whether the cached responses are encrypted."
  type        = bool
  default     = false
}

variable "require_authorization_for_cache_control" {
  description = "(Optional) Whether authorization is required for a cache invalidation request."
  type        = bool
  default     = true
}

variable "unauthorized_cache_control_header_strategy" {
  description = "(Optional) How to handle unauthorized requests for cache invalidation. The available values are `FAIL_WITH_403`, `SUCCEED_WITH_RESPONSE_HEADER`, `SUCCEED_WITHOUT_RESPONSE_HEADER`."
  type        = string
  default     = "SUCCEED_WITH_RESPONSE_HEADER"
}

################################
# API Gateway API Key Variables
################################
variable "enable_api_key" {
  description = "(Optional) Whether the API key can be used by callers. Defaults to `true`."
  type        = bool
  default     = true
}

variable "api_key_name" {
  description = "(Required) Name of the API key."
  type        = string
  default     = null
}

variable "api_key_description" {
  description = "(Optional) API key description. Defaults to `Managed by Terraform`."
  type        = string
  default     = null
}

###################################
# API Gateway Usage Plan Variables
###################################
variable "create_usage_plan" {
  description = "Allows creation of a usage plan. (Requires `var.enable_api_key = true`)"
  type        = bool
  default     = false
}

variable "usage_plans" {
  description = "Map of objects that define the usage plan to be created."
  type = list(
    object({
      name         = string
      description  = string
      burst_limit  = number
      rate_limit   = number
      quota_limit  = number
      quota_offset = number
      quota_period = string
      stages       = list(string)
    })
  )
}

variable "api_keys" {
  description = "Map of objects that define the usage plan to be created."
  type = list(
    object({
      name       = string
      key_type   = string
      usage_plan = string
    })
  )
}

variable "client_name" {
  description = "client name to use this api."
  type        = string
  default     = null
}

variable "limit" {
  description = "(Optional) - Maximum number of requests that can be made in a given time period."
  type        = number
  default     = 20
}

variable "offset" {
  description = "(Optional) - Number of requests subtracted from the given limit in the initial time period."
  type        = number
  default     = 2
}

variable "period" {
  description = "(Optional) - Time period in which the limit applies. Valid values are `DAY`, `WEEK` or `MONTH`."
  type        = string
  default     = "WEEK"
}

variable "burst_limit" {
  description = "(Optional) - The API request burst limit, the maximum rate limit over a time ranging from one to a few seconds, depending upon whether the underlying token bucket is at its full capacity."
  type        = number
  default     = 5
}

variable "rate_limit" {
  description = "(Optional) - The API request steady-state rate limit."
  type        = number
  default     = 10
}

################
# WAF Variables
################
variable "enable_waf" {
  description = "Enables associating existing WAF ACL to all stages."
  type        = bool
  default     = false
}
variable "waf_acl" {
  description = "(Required) The ID of the WAF Regional WebACL to create an association."
  type        = string
  default     = null
}

#######################
# CloudWatch Variables
#######################
variable "cloudwatch_role_arn" {
  description = "(Required) for the `api_gateway_account` resource."
  type        = string
}

variable "cloudwatch_policy_name" {
  description = "(Optional) The name of the role policy. If omitted, Terraform will assign a random, unique name."
  type        = string
}

variable "log_group_name" {
  description = "(Optional, Forces new resource) The name of the log group. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = string
  default     = 7
}

variable "log_group_kms_key" {
  description = "(Optional) The ARN of the KMS Key to use when encrypting log data. Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
  type        = string
  default     = null
}
