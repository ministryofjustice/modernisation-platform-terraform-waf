
output "web_acl_arn" {
  value = try(module.waf.web_acl_arn, "")
}

output "ip_set_arn" {
  value = try(module.waf.ip_set_arn, "")
}

output "log_group_name" {
  value = try(module.waf.log_group_name, "")
}

output "web_acl_name" {
  value = try(module.waf.web_acl_name, "")
}

