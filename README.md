# Modernisation Platform Terraform Module Template 

[![Standards Icon]][Standards Link] [![Format Code Icon]][Format Code Link] [![Scorecards Icon]][Scorecards Link] [![SCA Icon]][SCA Link] [![Terraform SCA Icon]][Terraform SCA Link]

## Usage

```hcl

module "template" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-module-template"

  tags             = local.tags
  application_name = local.application_name

}

```
<!--- BEGIN_TF_DOCS --->


<!--- END_TF_DOCS --->

## Looking for issues?
If you're looking to raise an issue with this module, please create a new issue in the [Modernisation Platform repository](https://github.com/ministryofjustice/modernisation-platform/issues).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.mp_waf_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.mp_waf_cloudwatch_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_ssm_parameter.ip_block_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_wafv2_ip_set.mp_waf_ip_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_web_acl.mp_waf_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.mp_waf_acl_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.mp_waf_cloudwatch_log_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_iam_policy_document.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Application identifier used for naming and tagging. | `string` | n/a | yes |
| <a name="input_associated_resource_arns"></a> [associated\_resource\_arns](#input\_associated\_resource\_arns) | List of resource ARNs (e.g. ALB, CloudFront distribution) to associate with the Web ACL. | `list(string)` | `[]` | no |
| <a name="input_blocked_ips"></a> [blocked\_ips](#input\_blocked\_ips) | List of IPv4/IPv6 addresses or CIDR ranges to block via the IP set. | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g. dev, test, prod) used for naming and tagging. | `string` | `"production"` | no |
| <a name="input_ip_address_version"></a> [ip\_address\_version](#input\_ip\_address\_version) | IP version for the IP set (IPV4 or IPV6). | `string` | `"IPV4"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Retention period for the WAF logs. | `number` | `365` | no |
| <a name="input_managed_rule_groups"></a> [managed\_rule\_groups](#input\_managed\_rule\_groups) | List of managed rule groups to enable. Each object supports:<br/>  * name            – (Required) Rule group name, e.g. "AWSManagedRulesCommonRuleSet".<br/>  * vendor\_name     – (Optional) Defaults to "AWS".<br/>  * override\_action – (Optional) "count" or "none". Defaults to "count".<br/>  * priority        – (Optional) Rule priority. If omitted, the module assigns priorities starting at 10. | <pre>list(object({<br/>    name            = string<br/>    vendor_name     = optional(string, "AWS")<br/>    override_action = optional(string, "count")<br/>    priority        = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "AWSManagedRulesKnownBadInputsRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesCommonRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesSQLiRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesLinuxRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesAnonymousIpList"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesBotControlRuleSet"<br/>  }<br/>]</pre> | no |
| <a name="input_ssm_parameter_name"></a> [ssm\_parameter\_name](#input\_ssm\_parameter\_name) | Name of the SSM SecureString parameter that stores the JSON‑encoded blocked IP list. | `string` | `"/waf/ip_block_list"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags applied to all resources. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ip_set_arn"></a> [ip\_set\_arn](#output\_ip\_set\_arn) | ARN of the IP set used for blocking. |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the CloudWatch log group containing WAF logs. |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the WAFv2 Web ACL. |
<!-- END_TF_DOCS -->

[Standards Link]: https://github-community.service.justice.gov.uk/repository-standards/modernisation-platform-terraform-module-template "Repo standards badge."
[Standards Icon]: https://github-community.service.justice.gov.uk/repository-standards/api/modernisation-platform-terraform-module-template/badge
[Format Code Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-module-template/format-code.yml?labelColor=231f20&style=for-the-badge&label=Formate%20Code
[Format Code Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-module-template/actions/workflows/format-code.yml
[Scorecards Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-module-template/scorecards.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Scorecards
[Scorecards Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-module-template/actions/workflows/scorecards.yml
[SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-module-template/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Secure%20Code%20Analysis
[SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-module-template/actions/workflows/code-scanning.yml
[Terraform SCA Icon]: https://img.shields.io/github/actions/workflow/status/ministryofjustice/modernisation-platform-terraform-module-template/code-scanning.yml?branch=main&labelColor=231f20&style=for-the-badge&label=Terraform%20Static%20Code%20Analysis
[Terraform SCA Link]: https://github.com/ministryofjustice/modernisation-platform-terraform-module-template/actions/workflows/terraform-static-analysis.yml
