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
}