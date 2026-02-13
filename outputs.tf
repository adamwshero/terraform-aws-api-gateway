output "api_gateway_rest_api_arn" {
  description = "Arn of the REST API."
  value       = aws_api_gateway_rest_api.this.arn
}

output "api_gateway_rest_api_name" {
  description = "Name of the REST API."
  value       = aws_api_gateway_rest_api.this.name
}

output "api_gateway_rest_api_id" {
  description = "Id of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_rest_api_execution_arn" {
  description = "Execution Arn of the REST API."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "api_gateway_rest_api_stage_arn" {
  description = "Arn of the deployed stage(s)."
  value       = aws_api_gateway_stage.this[0].arn
}

output "api_gateway_rest_api_stage_id" {
  description = "Id of the deployed stage(s)."
  value       = aws_api_gateway_stage.this[0].id
}

output "api_gateway_rest_api_stage_invoke_url" {
  description = "Invoke URL of the deployed stage(s)."
  value       = aws_api_gateway_stage.this[0].invoke_url
}

output "api_gateway_rest_api_stage_execution_arn" {
  description = "Execution arn of the deployed stage(s)."
  value       = aws_api_gateway_stage.this[0].execution_arn
}

output "api_gateway_rest_api_stage_web_acl" {
  description = "WAF Access Control List for the stage(s)"
  value       = aws_api_gateway_stage.this[0].web_acl_arn
}

output "aws_api_gateway_domain_name" {
  description = "api gateway domain name"
  value       = { for k, v in aws_api_gateway_domain_name.regional_acm : k => v }
  sensitive   = true
}
