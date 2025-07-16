###############################################################################
#  Input variables for WAF module
###############################################################################

# Application identifier used for naming and tagging resources
variable "application_name" {
  description = "Application identifier used for naming and tagging."
  type        = string
}

# Common tags to apply to all resources
variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking / geographic blocking
###############################################################################

# Block traffic from outside the United Kingdom (GB) if true
variable "block_non_uk_traffic" {
  description = "If true, add a WAF rule that blocks any request not originating from the United Kingdom (GB)."
  type        = bool
  default     = false
}

# IPv4 or IPv6 selection for the WAF IP set
variable "ip_address_version" {
  description = "IP version for the IP set (IPV4 or IPV6)."
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_address_version)
    error_message = "ip_address_version must be either \"IPV4\" or \"IPV6\"."
  }
}

###############################################################################
# DDoS protection / rate limiting
###############################################################################

# Enable Shield-style rate limiting
variable "enable_ddos_protection" {
  description = "If true (default), create a Shield‑style rate‑based blocking rule at the WebACL."
  type        = bool
  default     = true
}

# Threshold for rate-based rule (requests per 5-min)
variable "ddos_rate_limit" {
  description = "Requests per 5‑minute window that triggers the DDoS rate‑based block. Required when enable_ddos_protection = true."
  type        = number
  validation {
    condition     = var.ddos_rate_limit > 0
    error_message = "ddos_rate_limit must be a positive number."
  }
}

###############################################################################
# AWS Managed Rule Groups
###############################################################################

# Whether managed rule groups should block (true) or just monitor (false)
variable "managed_rule_enforce" {
  description = "When true, AWS Managed Rule Groups are set to block (override_action = \"none\"). When false (default) they run in count mode."
  type        = bool
  default     = false
}

# List of managed rule groups to apply
variable "managed_rule_groups" {
  description = <<EOT
List of managed rule groups to enable. Each object supports:
  * name            – (Required) Rule group name, e.g. "AWSManagedRulesCommonRuleSet".
  * vendor_name     – (Optional) Defaults to "AWS".
  * override_action – (Optional) "count" or "none". If omitted, the module uses managed_rule_enforce to decide.
  * priority        – (Optional) Rule priority. If omitted, the module assigns priorities starting at 10.
EOT
  type = list(object({
    name            = string
    vendor_name     = optional(string, "AWS")
    override_action = optional(string)
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

# Explicit override for managed rule actions (true = block, false = count)
variable "managed_rule_actions" {
  type        = map(bool)
  description = "Map of AWS Managed Rule Group names to boolean flag indicating whether to block (true) or count (false)."
}

# Optional additional managed rule groups (e.g. third-party)
variable "additional_managed_rules" {
  description = "Additional AWS Managed Rule Groups to include in the WebACL."
  type = list(object({
    name            = string
    vendor_name     = string
    version         = optional(string)
    override_action = optional(string) # 'none' or 'count'
  }))
  default = []
}

###############################################################################
# Logging configuration
###############################################################################

# Name of SSM parameter to hold the IP block list
variable "ssm_parameter_name" {
  description = "Name of the SSM SecureString parameter that stores the JSON‑encoded blocked IP list."
  type        = string
  default     = "/waf/ip_block_list"
}

# List of resource ARNs (e.g., ALBs, CloudFront distributions) to associate with this WebACL
variable "associated_resource_arns" {
  description = "List of resource ARNs (e.g. ALB, CloudFront distribution) to associate with the Web ACL."
  type        = list(string)
  default     = []
}

# CloudWatch log retention period in days
variable "log_retention_in_days" {
  description = "Retention period for the WAF logs."
  type        = number
  default     = 365
}

# Existing CloudWatch log group ARN (if not auto-created)
variable "log_destination_arn" {
  description = "Optional ARN of an existing CloudWatch Log Group to send WAF logs to"
  type        = string
  default     = null
}

###############################################################################
# Centralised logging and alerting
###############################################################################

# Core logging account to forward logs to
variable "core_logging_account_id" {
  description = "Account ID for core logging"
  type        = string
  default     = ""
}

# Whether to enable forwarding logs to the core logging account
variable "enable_core_logging" {
  description = "Whether to enable forwarding logs to the core logging account"
  type        = bool
  default     = true
}

# Enable creation of DDoS detection CloudWatch alarms
variable "enable_ddos_alarms" {
  type        = bool
  description = "Enable DDoS protection CloudWatch alarms"
  default     = true
}

# Enable integration with PagerDuty for alerting
variable "enable_pagerduty_integration" {
  type        = bool
  description = "Enable PagerDuty SNS integration for DDoS alarms"
  default     = true
}

# Map of monitored resources (by ARN) for DDoS detection alarms
variable "ddos_alarm_resources" {
  description = "Map of resources to monitor for DDoS alarms. Each value must contain 'arn'."
  type = map(object({
    arn = string
  }))
  default = {}
}
