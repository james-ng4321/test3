# ---------------------------------------------------------------------------
# Monitor Scheduled Query Rules (Log Alerts) — V2
#
# Used for alerts that read from a Log Analytics workspace, e.g. VM heartbeat,
# guest filesystem free space, and AKS Container Insights pod queries.
# ---------------------------------------------------------------------------

locals {
  monitor_scheduled_query_rule_scope_id = {
    for rule in coalesce(var.monitor_scheduled_query_rules, []) : rule.name => (
      rule.scope_resource_module == null ? null :
      rule.scope_resource_module == "azurerm_log_analytics_workspace" ? azurerm_log_analytics_workspace.main[rule.scope_resource_name].id :
      rule.scope_resource_module == "azurerm_linux_virtual_machine" ? azurerm_linux_virtual_machine.main[rule.scope_resource_name].id :
      rule.scope_resource_module == "azurerm_kubernetes_cluster" ? azurerm_kubernetes_cluster.main[rule.scope_resource_name].id :
      null
    )
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "main" {
  for_each = {
    for rule in coalesce(var.monitor_scheduled_query_rules, []) : rule.name => rule
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  description         = each.value.description
  display_name        = each.value.display_name
  enabled             = each.value.enabled
  severity            = each.value.severity

  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration

  scopes = (
    each.value.scopes != null ? each.value.scopes :
    [local.monitor_scheduled_query_rule_scope_id[each.value.name]]
  )

  target_resource_types = each.value.target_resource_types
  auto_mitigation_enabled              = each.value.auto_mitigation_enabled
  workspace_alerts_storage_enabled     = each.value.workspace_alerts_storage_enabled
  mute_actions_after_alert_duration    = each.value.mute_actions_after_alert_duration
  query_time_range_override            = each.value.query_time_range_override
  skip_query_validation                = each.value.skip_query_validation

  criteria {
    query                   = each.value.criteria.query
    operator                = each.value.criteria.operator
    threshold               = each.value.criteria.threshold
    time_aggregation_method = each.value.criteria.time_aggregation_method
    metric_measure_column   = each.value.criteria.metric_measure_column
    resource_id_column      = each.value.criteria.resource_id_column

    dynamic "dimension" {
      for_each = each.value.criteria.dimension != null ? each.value.criteria.dimension : []
      iterator = dimension
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

    dynamic "failing_periods" {
      for_each = each.value.criteria.failing_periods != null ? [each.value.criteria.failing_periods] : []
      iterator = failing_periods
      content {
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
        number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []
    iterator = action
    content {
      action_groups = (
        action.value.action_group_ids != null ? action.value.action_group_ids :
        [for ag_name in coalesce(action.value.action_group_names, []) : azurerm_monitor_action_group.main[ag_name].id]
      )
      custom_properties = action.value.custom_properties
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_monitor_action_group.main,
    azurerm_log_analytics_workspace.main,
    azurerm_linux_virtual_machine.main,
    azurerm_kubernetes_cluster.main
  ]
}
