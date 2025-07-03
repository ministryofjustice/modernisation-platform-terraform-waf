#---------------------------------------------------------------------
# IP block list – stored in SSM so Ops/SOC can update it without code
#---------------------------------------------------------------------
resource "aws_ssm_parameter" "ip_block_list" {
  # checkov:skip=CKV_AWS_337: Standard (AWS‑managed) KMS key is sufficient for SecureString
  name  = var.ssm_parameter_name
  type  = "SecureString"
  value = "[]" # initialise with an empty JSON array – can be updated later outside TF

  lifecycle {
    ignore_changes = [value] # don’t clobber manual updates on the parameter
  }
}

#---------------------------------------------------------------------
# IP set referencing the parameter above
#---------------------------------------------------------------------
resource "aws_wafv2_ip_set" "mp_waf_ip_set" {
  name               = "${local.base_name}-ip-set"
  scope              = "REGIONAL"
  ip_address_version = var.ip_address_version
  description = "Addresses blocked by ${local.base_name} - populated from SSM"
  addresses          = jsondecode(aws_ssm_parameter.ip_block_list.value)
  tags               = local.tags
}

#---------------------------------------------------------------------
# Generate a stable priority order for managed rule groups
#---------------------------------------------------------------------
locals {
  managed_rule_groups_with_priority = [
    for idx, rg in var.managed_rule_groups :
    merge(rg, { priority = coalesce(rg.priority, 10 + idx) })
  ]
}

#---------------------------------------------------------------------
# Web ACL
#---------------------------------------------------------------------
resource "aws_wafv2_web_acl" "mp_waf_acl" {
  name        = local.base_name
  scope       = "REGIONAL"
  description = "AWS WAF protecting ${local.base_name}"

  default_action {
    allow {}
  }

  # Rule 1 – block explicitly listed IPs
  rule {
    name     = "${local.base_name}-blocked-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.mp_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.base_name}-blocked-ip"
      sampled_requests_enabled   = true
    }
  }

  # Managed rule groups – built dynamically
  dynamic "rule" {
    for_each = local.managed_rule_groups_with_priority
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.base_name
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

#---------------------------------------------------------------------
# Logging
#---------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "mp_waf_cloudwatch_log_group" {
  name              = "aws-waf-logs-${local.base_name}"
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

data "aws_iam_policy_document" "waf" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "mp_waf_cloudwatch_log_policy" {
  policy_name     = "${local.base_name}-resource-policy"
  policy_document = data.aws_iam_policy_document.waf.json
}

resource "aws_wafv2_web_acl_logging_configuration" "mp_waf_cloudwatch_log_config" {
  resource_arn            = aws_wafv2_web_acl.mp_waf_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group.arn]

  depends_on = [aws_cloudwatch_log_resource_policy.mp_waf_cloudwatch_log_policy]
}

#---------------------------------------------------------------------
# Optional association to ALBs / CloudFront / API Gateway, etc.
#---------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "mp_waf_acl_association" {
  for_each     = toset(var.associated_resource_arns)
  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.mp_waf_acl.arn
}
