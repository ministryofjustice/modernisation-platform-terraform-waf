locals {
  base_name = lower(format("%s-%s-waf", var.application_name, var.environment))
  tags      = merge(var.tags, { Name = local.base_name })
}