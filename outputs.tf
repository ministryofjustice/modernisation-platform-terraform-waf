/* outputs.tf */
output "web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.mp_waf_acl.arn
}

output "ip_set_arn" {
  description = "ARN of the IP set used for blocking."
  value       = aws_wafv2_ip_set.mp_waf_ip_set.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group containing WAF logs."
  value = aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group[0].arn
}

output "waf_log_group_arn" {
  description = "ARN of the log group receiving WAF logs"
  value       = coalesce(var.log_destination_arn, aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group[0].arn)
}

output "web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.mp_waf_acl.name
}
