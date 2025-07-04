###############################################################################
# 1.  SSM parameter that holds the JSON array of blocked IPs
###############################################################################
resource "aws_ssm_parameter" "ip_block_list" {
  # checkov:skip=CKV_AWS_337 – AWS‑managed KMS key is fine
  name  = var.ssm_parameter_name
  type  = "SecureString"
  value = "[]"          # initialise empty

  lifecycle {
    ignore_changes = [value]   # allow SOC to edit manually
  }
}

###############################################################################
# 2.  IP set fed from the SSM parameter (used in Rule #1)
###############################################################################
resource "aws_wafv2_ip_set" "mp_waf_ip_set" {
  name               = "${local.base_name}-ip-set"
  scope              = "REGIONAL"
  ip_address_version = var.ip_address_version
  description        = "Addresses blocked by ${local.base_name} populated from SSM"
  addresses          = jsondecode(aws_ssm_parameter.ip_block_list.value)
  tags               = local.tags
}

###############################################################################
# 3.  CloudWatch log group for WAF logging
###############################################################################
resource "aws_cloudwatch_log_group" "mp_waf_cloudwatch_log_group" {
  name              = "aws-waf-logs-${local.base_name}"
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

###############################################################################
# 4.  Web ACL with optional rules
###############################################################################
resource "aws_wafv2_web_acl" "mp_waf_acl" {
  name        = local.base_name
  scope       = "REGIONAL"          # change to CLOUDFRONT if needed
  description = "AWS WAF protecting ${local.base_name}"

  #----------------------------------------------------------
  # Default action = allow
  #----------------------------------------------------------
  default_action {
    allow {}
  }

  #----------------------------------------------------------
  # Rule #1 – explicit IP block list
  #----------------------------------------------------------
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

  #----------------------------------------------------------
  # Rule #2 – optional Shield‑style rate‑based DDoS block
  #----------------------------------------------------------
  dynamic "rule" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      name     = "shield-block"
      priority = 2

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.ddos_rate_limit     # required when enabled
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "shield-block"
        sampled_requests_enabled   = true
      }
    }
  }

  #----------------------------------------------------------
  # Rule #3 – optional geo block (everything except UK)
  #----------------------------------------------------------
  dynamic "rule" {
    for_each = var.block_non_uk_traffic ? [1] : []
    content {
      name     = "block-non-uk"
      priority = 3

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = ["GB"]
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "block-non-uk"
        sampled_requests_enabled   = true
      }
    }
  }

  #----------------------------------------------------------
  # Rule #4+ – managed rule groups
  #----------------------------------------------------------
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

  #----------------------------------------------------------
  # ACL‑level visibility settings
  #----------------------------------------------------------
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.base_name
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

###############################################################################
# 5.  Wire WAF logging to CloudWatch
###############################################################################
data "aws_iam_policy_document" "waf" {
  statement {
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "mp_waf_log_policy" {
  policy_name     = "${local.base_name}-resource-policy"
  policy_document = data.aws_iam_policy_document.waf.json
}

resource "aws_wafv2_web_acl_logging_configuration" "mp_waf_log_config" {
  resource_arn            = aws_wafv2_web_acl.mp_waf_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group.arn]

  depends_on = [aws_cloudwatch_log_resource_policy.mp_waf_log_policy]
}

###############################################################################
# 6.  Optional association to ALB / CloudFront / API Gateway, etc.
###############################################################################
resource "aws_wafv2_web_acl_association" "mp_waf_acl_association" {
  for_each     = toset(var.associated_resource_arns)
  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.mp_waf_acl.arn
}
