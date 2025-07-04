variable "application_name" {
  description = "Application identifier used for naming and tagging."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

# --- Networking / geo ------------------------------------------------
variable "block_non_uk_traffic" {
  description = "If true, add a WAF rule that blocks any request not originating from the United Kingdom (GB)."
  type        = bool
  default     = false
}

variable "ip_address_version" {
  description = "IP version for the IP set (IPV4 or IPV6)."
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_address_version)
    error_message = "ip_address_version must be either \"IPV4\" or \"IPV6\"."
  }
}

# --- DDoS / rate limiting -------------------------------------------
variable "enable_ddos_protection" {
  description = "If true (default), create a Shield‑style rate‑based blocking rule at the WebACL."
  type        = bool
  default     = true
}

variable "ddos_rate_limit" {
  description = "Requests per 5‑minute window that triggers the DDoS rate‑based block. Required when enable_ddos_protection = true."
  type        = number
  default     = null
  validation {
    condition = var.enable_ddos_protection == false || (var.enable_ddos_protection && var.ddos_rate_limit != null && var.ddos_rate_limit > 0)
    error_message = "ddos_rate_limit must be set to a positive integer when enable_ddos_protection is true."
  }
}

# --- Managed rule groups --------------------------------------------
variable "managed_rule_enforce" {
  description = "When true, AWS Managed Rule Groups are set to block (override_action = \"none\"). When false (default) they run in count mode."
  type        = bool
  default     = false
}

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

# --- Misc ------------------------------------------------------------
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

variable "managed_rule_actions" {
  type = map(bool) # true = block, false = count
  description = "Map of AWS Managed Rule Group names to boolean flag indicating whether to block (true) or count (false)."
}