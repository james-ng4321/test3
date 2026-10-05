resource "azurerm_monitor_activity_log_alert" "main" {
  for_each = {
    for index, monitor_activity_log_alert in coalesce(var.monitor_activity_log_alerts, []) : monitor_activity_log_alert.name => monitor_activity_log_alert
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  scopes              = each.value.scopes

  criteria {
    category                = each.value.criteria.category
    caller                  = each.value.criteria.caller
    operation_name          = each.value.criteria.operation_name
    resource_provider       = each.value.criteria.resource_provider
    resource_providers      = each.value.criteria.resource_providers
    resource_type           = each.value.criteria.resource_type
    resource_types          = each.value.criteria.resource_types
    resource_group          = each.value.criteria.resource_group
    resource_groups         = each.value.criteria.resource_groups
    resource_id             = each.value.criteria.resource_id
    resource_ids            = each.value.criteria.resource_ids
    level                   = each.value.criteria.level
    levels                  = each.value.criteria.levels
    status                  = each.value.criteria.status
    statuses                = each.value.criteria.statuses
    sub_status              = each.value.criteria.sub_status
    sub_statuses            = each.value.criteria.sub_statuses
    recommendation_type     = each.value.criteria.recommendation_type
    recommendation_category = each.value.criteria.recommendation_category
    recommendation_impact   = each.value.criteria.recommendation_impact

    dynamic "resource_health" {
      for_each = each.value.criteria.resource_health != null ? [each.value.criteria.resource_health] : []
      iterator = resource_health
      content {
        current  = resource_health.value.current
        previous = resource_health.value.previous
        reason   = resource_health.value.reason
      }
    }

    dynamic "service_health" {
      for_each = each.value.criteria.service_health != null ? [each.value.criteria.service_health] : []
      iterator = service_health
      content {
        events    = service_health.value.events
        locations = service_health.value.locations
        services  = service_health.value.services
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action != null ? each.value.action : []
    iterator = action
    content {
      action_group_id    = action.value.action_group_id != null ? action.value.action_group_id : azurerm_monitor_action_group.main[action.value.action_group_name].id
      webhook_properties = action.value.webhook_properties
    }
  }

  enabled     = each.value.enabled
  description = each.value.description
  tags        = each.value.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_monitor_action_group.main
  ]
}
