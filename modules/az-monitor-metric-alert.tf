# ---------------------------------------------------------------------------
# Monitor Metric Alert
#
# Wraps azurerm_monitor_metric_alert. Each entry in var.monitor_metric_alerts
# either provides explicit scopes (list of resource IDs) or resolves the scope
# from target_resource_module + target_resource_name (looked up against the
# resources created by this module).
# ---------------------------------------------------------------------------

locals {
  monitor_metric_alert_resource_id = {
    for alert in coalesce(var.monitor_metric_alerts, []) : alert.name => (
      alert.target_resource_module == null ? null :
      alert.target_resource_module == "azurerm_linux_virtual_machine" ? azurerm_linux_virtual_machine.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_windows_virtual_machine" ? azurerm_windows_virtual_machine.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_kubernetes_cluster" ? azurerm_kubernetes_cluster.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_application_gateway" ? azurerm_application_gateway.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_web_application_firewall_policy" ? azurerm_web_application_firewall_policy.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_mysql_flexible_server" ? azurerm_mysql_flexible_server.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_key_vault" ? azurerm_key_vault.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_container_registry" ? azurerm_container_registry.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_public_ip" ? azurerm_public_ip.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_public_ip_application_gateway_frontend" ? azurerm_public_ip.application_gateway_frontend[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_recovery_services_vault" ? azurerm_recovery_services_vault.main[alert.target_resource_name].id :
      alert.target_resource_module == "azurerm_storage_account" ? azurerm_storage_account.main[alert.target_resource_name].id :
      null
    )
  }
}

resource "azurerm_monitor_metric_alert" "main" {
  for_each = {
    for alert in coalesce(var.monitor_metric_alerts, []) : alert.name => alert
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled
  auto_mitigate       = each.value.auto_mitigate
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  scopes = (
    each.value.scopes != null ? each.value.scopes :
    [local.monitor_metric_alert_resource_id[each.value.name]]
  )

  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location

  dynamic "criteria" {
    for_each = each.value.criteria != null ? each.value.criteria : []
    iterator = criteria
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimension != null ? criteria.value.dimension : []
        iterator = dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria != null ? each.value.dynamic_criteria : []
    iterator = dynamic_criteria
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name              = dynamic_criteria.value.metric_name
      aggregation              = dynamic_criteria.value.aggregation
      operator                 = dynamic_criteria.value.operator
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      ignore_data_before       = dynamic_criteria.value.ignore_data_before
      skip_metric_validation   = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension != null ? dynamic_criteria.value.dimension : []
        iterator = dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
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

  tags = each.value.tags

  depends_on = [
    azurerm_monitor_action_group.main,
    azurerm_linux_virtual_machine.main,
    azurerm_kubernetes_cluster.main,
    azurerm_application_gateway.main,
    azurerm_web_application_firewall_policy.main,
    azurerm_mysql_flexible_server.main,
    azurerm_key_vault.main,
    azurerm_container_registry.main,
    azurerm_public_ip.main,
    azurerm_public_ip.application_gateway_frontend,
    azurerm_recovery_services_vault.main,
    azurerm_storage_account.main
  ]
}
