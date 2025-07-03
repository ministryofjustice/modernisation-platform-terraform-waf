variable "application_name" {
  description = "Application identifier used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, test, prod) used for naming and tagging."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
}

variable "blocked_ips" {
  description = "List of IPv4/IPv6 addresses or CIDR ranges to block via the IP set."
  type        = list(string)
  default     = []
}

variable "ip_address_version" {
  description = "IP version for the IP set (IPV4 or IPV6)."
  type        = string
  default     = "IPV4"
}

variable "ssm_parameter_name" {
  description = "Name of the SSM SecureString parameter that stores the JSON‑encoded blocked IP list."
  type        = string
  default     = "/waf/ip_block_list"
}

variable "associated_resource_arns" {
  description = "List of resource ARNs (e.g. ALB, CloudFront distribution) to associate with the Web ACL."
  type        = list(string)
  default     = []
}

variable "log_retention_in_days" {
  description = "Retention period for the WAF logs."
  type        = number
  default     = 365
}

variable "managed_rule_groups" {
  description = <<EOT
List of managed rule groups to enable. Each object supports:
  * name            – (Required) Rule group name, e.g. "AWSManagedRulesCommonRuleSet".
  * vendor_name     – (Optional) Defaults to "AWS".
  * override_action – (Optional) "count" or "none". Defaults to "count".
  * priority        – (Optional) Rule priority. If omitted, the module assigns priorities starting at 10.
EOT
  type = list(object({
    name            = string
    vendor_name     = optional(string, "AWS")
    override_action = optional(string, "count")
    priority        = optional(number)
  }))
  default = [
    { name = "AWSManagedRulesKnownBadInputsRuleSet" },
    { name = "AWSManagedRulesCommonRuleSet" },
    { name = "AWSManagedRulesSQLiRuleSet" },
    { name = "AWSManagedRulesLinuxRuleSet" },
    { name = "AWSManagedRulesAnonymousIpList" },
    { name = "AWSManagedRulesBotControlRuleSet" }
  ]
}
