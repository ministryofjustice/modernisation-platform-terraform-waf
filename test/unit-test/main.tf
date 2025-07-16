module "waf" {
  source                  = "../../" # path to your root module
    providers = {
    aws.modernisation-platform = aws.testing-ci-user
  }
  enable_pagerduty_integration         = false

  core_logging_account_id = local.environment_management.account_ids["testing-test"]
  enable_ddos_protection  = true
  ddos_rate_limit         = 1500
  block_non_uk_traffic    = true
  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = false
    AWSManagedRulesCommonRuleSet         = false
    AWSManagedRulesSQLiRuleSet           = false
    AWSManagedRulesLinuxRuleSet          = false
    AWSManagedRulesAnonymousIpList       = false
    AWSManagedRulesBotControlRuleSet     = false
  }
  application_name    = local.application_name
  tags                = local.tags
  enable_core_logging = false
}
