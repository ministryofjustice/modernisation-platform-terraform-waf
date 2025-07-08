locals {
  base_name = lower(format("%s-waf", var.application_name))
  tags      = merge(var.tags, { Name = local.base_name })

  managed_rule_groups_with_priority = [
    for idx, group in keys(var.managed_rule_actions) : {
      name            = group
      vendor_name     = "AWS"
      priority        = 10 + idx
      override_action = var.managed_rule_actions[group] ? "none" : "count"
    }
  ]

  ddos_enabled = var.enable_ddos_protection

  ddos_rate_limit_valid = !local.ddos_enabled || (
    local.ddos_enabled && var.ddos_rate_limit > 0
  )
}

resource "null_resource" "validate_ddos_config" {
  count = var.enable_ddos_protection && var.ddos_rate_limit == null ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: ddos_rate_limit must be set when enable_ddos_protection is true' && exit 1"
  }
}