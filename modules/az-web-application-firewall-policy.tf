resource "azurerm_web_application_firewall_policy" "main" {
  for_each = {
    for index, waf_policy in coalesce(var.web_application_firewall_policies, []) : waf_policy.name => waf_policy
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  policy_settings {
    enabled                          = each.value.policy_settings.enabled
    mode                             = each.value.policy_settings.mode
    request_body_check               = each.value.policy_settings.request_body_check
    file_upload_limit_in_mb          = each.value.policy_settings.file_upload_limit_in_mb
    max_request_body_size_in_kb      = each.value.policy_settings.max_request_body_size_in_kb
    request_body_inspect_limit_in_kb = each.value.policy_settings.request_body_inspect_limit_in_kb
    request_body_enforcement         = each.value.policy_settings.request_body_enforcement
  }

  dynamic "managed_rules" {
    for_each = each.value.managed_rules != null ? [each.value.managed_rules] : []

    content {
      dynamic "exclusion" {
        for_each = coalesce(managed_rules.value.exclusions, [])

        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator

          dynamic "excluded_rule_set" {
            for_each = coalesce(exclusion.value.excluded_rule_sets, [])

            content {
              type    = excluded_rule_set.value.type
              version = excluded_rule_set.value.version

              dynamic "rule_group" {
                for_each = coalesce(excluded_rule_set.value.rule_groups, [])

                content {
                  rule_group_name = rule_group.value.rule_group_name
                  excluded_rules  = rule_group.value.excluded_rules
                }
              }
            }
          }
        }
      }

      dynamic "managed_rule_set" {
        for_each = coalesce(managed_rules.value.managed_rule_sets, [])

        content {
          type    = managed_rule_set.value.type
          version = managed_rule_set.value.version

          dynamic "rule_group_override" {
            for_each = coalesce(managed_rule_set.value.rule_group_overrides, [])

            content {
              rule_group_name = rule_group_override.value.rule_group_name

              dynamic "rule" {
                for_each = coalesce(rule_group_override.value.rules, [])

                content {
                  id      = rule.value.id
                  enabled = rule.value.enabled
                  action  = rule.value.action
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "custom_rules" {
    for_each = coalesce(each.value.custom_rules, [])

    content {
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type
      action    = custom_rules.value.action

      dynamic "match_conditions" {
        for_each = coalesce(custom_rules.value.match_conditions, [])

        content {
          dynamic "match_variables" {
            for_each = coalesce(match_conditions.value.match_variables, [])

            content {
              variable_name = match_variables.value.variable_name
              selector      = match_variables.value.selector
            }
          }

          operator           = match_conditions.value.operator
          negation_condition = match_conditions.value.negation_condition
          match_values       = match_conditions.value.match_values
          transforms         = match_conditions.value.transforms
        }
      }
    }
  }

  # Stops Terraform deleting the HTTPDDoS ruleset, which azurerm 4.62.0 can't
  # declare. Exclusions/custom rules unaffected. Remove once supported:
  # https://github.com/hashicorp/terraform-provider-azurerm/pull/32708
  lifecycle {
    ignore_changes = [managed_rules[0].managed_rule_set]
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}
