package test

import (
	"testing"

	awssdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/wafv2"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestWAFModule(t *testing.T) {
	t.Parallel()

	defaultVars := map[string]interface{}{
		"application_name":       "terratest-example",
		"enable_ddos_protection": true,
		"ddos_rate_limit":        1500,
		"block_non_uk_traffic":   true,
		"associated_resource_arns": []string{},
		"tags": map[string]string{
			"Environment": "test",
			"Terraform":   "true",
		},
		"managed_rule_actions": map[string]bool{
			"AWSManagedRulesKnownBadInputsRuleSet": true,
			"AWSManagedRulesCommonRuleSet":         true,
			"AWSManagedRulesSQLiRuleSet":           false,
			"AWSManagedRulesLinuxRuleSet":          false,
			"AWSManagedRulesAnonymousIpList":       true,
			"AWSManagedRulesBotControlRuleSet":     true,
		},
		"additional_managed_rules": []map[string]interface{}{
			{
				"name":            "AWSManagedRulesPHPRuleSet",
				"vendor_name":     "AWS",
				"override_action": "count",
			},
		},
	}

	opts := &terraform.Options{
		TerraformDir: "../",
		Vars:         defaultVars,
	}

	terraform.InitAndApply(t, opts)

	// Run CheckTags before destroy
	t.Run("CheckTags", func(t *testing.T) {
		sess := session.Must(session.NewSession(&awssdk.Config{
			Region: awssdk.String("eu-west-2"),
		}))
		wafClient := wafv2.New(sess)

		aclArn := terraform.Output(t, opts, "web_acl_arn")
		resp, err := wafClient.ListTagsForResource(&wafv2.ListTagsForResourceInput{
			ResourceARN: awssdk.String(aclArn),
		})
		assert.NoError(t, err)

		tagList := resp.TagInfoForResource.TagList
		var found bool
		for _, tag := range tagList {
			if awssdk.StringValue(tag.Key) == "Environment" && awssdk.StringValue(tag.Value) == "test" {
				found = true
			}
		}
		assert.True(t, found, "Expected Environment=test tag to be set")
	})

	// Cleanup
	defer terraform.Destroy(t, opts)

	// Basic output check
	webAclArn := terraform.Output(t, opts, "web_acl_arn")
	assert.Contains(t, webAclArn, "arn:aws:wafv2")

	// Test with DDoS protection disabled
	t.Run("DDoSDisabled", func(t *testing.T) {
		vars := defaultVars
		vars["enable_ddos_protection"] = false

		opts := &terraform.Options{
			TerraformDir: "../",
			Vars:         vars,
		}
		defer terraform.Destroy(t, opts)
		terraform.InitAndApply(t, opts)
	})

	// Test with all managed rules disabled
	t.Run("DisableAllManagedRules", func(t *testing.T) {
		vars := defaultVars
		vars["managed_rule_actions"] = map[string]bool{
			"AWSManagedRulesKnownBadInputsRuleSet": false,
			"AWSManagedRulesCommonRuleSet":         false,
		}

		opts := &terraform.Options{
			TerraformDir: "../",
			Vars:         vars,
		}
		defer terraform.Destroy(t, opts)
		terraform.InitAndApply(t, opts)
	})
}
