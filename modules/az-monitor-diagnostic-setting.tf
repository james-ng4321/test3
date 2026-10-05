locals {
  monitor_diagnostic_setting_azurerm_storage_account_ids = {
    for monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name =>
    {
      resource_id = azurerm_storage_account.main[monitor_diagnostic_setting.target_resource_name].id
    }
    if monitor_diagnostic_setting.target_resource_module == "azurerm_storage_account"
  }

  monitor_diagnostic_setting_azurerm_windows_web_app_ids = {
    for monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name =>
    {
      resource_id = azurerm_windows_web_app.main[monitor_diagnostic_setting.target_resource_name].id
    }
    if monitor_diagnostic_setting.target_resource_module == "azurerm_windows_web_app"
  }

  monitor_diagnostic_setting_azurerm_key_vault_ids = {
    for monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name =>
    {
      resource_id = azurerm_key_vault.main[monitor_diagnostic_setting.target_resource_name].id
    }
    if monitor_diagnostic_setting.target_resource_module == "azurerm_key_vault"
  }

  monitor_diagnostic_setting_azurerm_mysql_flexible_server_ids = {
    for monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name =>
    {
      resource_id = azurerm_mysql_flexible_server.main[monitor_diagnostic_setting.target_resource_name].id
    }
    if monitor_diagnostic_setting.target_resource_module == "azurerm_mysql_flexible_server"
  }

  monitor_diagnostic_setting_azurerm_application_gateway_ids = {
    for monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name =>
    {
      resource_id = azurerm_application_gateway.main[monitor_diagnostic_setting.target_resource_name].id
    }
    if monitor_diagnostic_setting.target_resource_module == "azurerm_application_gateway"
  }

  monitor_diagnostic_setting_resource_ids = merge(
    local.monitor_diagnostic_setting_azurerm_storage_account_ids,
    local.monitor_diagnostic_setting_azurerm_windows_web_app_ids,
    local.monitor_diagnostic_setting_azurerm_key_vault_ids,
    local.monitor_diagnostic_setting_azurerm_mysql_flexible_server_ids,
    local.monitor_diagnostic_setting_azurerm_application_gateway_ids
  )
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = {
    for index, monitor_diagnostic_setting in coalesce(var.monitor_diagnostic_settings, []) : monitor_diagnostic_setting.name => monitor_diagnostic_setting
  }

  name                           = each.value.name
  target_resource_id             = (each.value.target_resource_id != null ? each.value.target_resource_id : (each.value.storage_sub_resource_name != null ? "${azurerm_storage_account.main[each.value.target_resource_name].id}/${each.value.storage_sub_resource_name}/default/" : local.monitor_diagnostic_setting_resource_ids[each.value.name].resource_id))
  eventhub_name                  = each.value.eventhub_name
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id

  log_analytics_workspace_id = each.value.log_analytics_workspace_id != null ? each.value.log_analytics_workspace_id : each.value.log_analytics_workspace_name != null ? azurerm_log_analytics_workspace.main[each.value.log_analytics_workspace_name].id : null
  storage_account_id         = each.value.storage_account_id != null ? each.value.storage_account_id : each.value.storage_account_name != null ? azurerm_storage_account.main[each.value.storage_account_name].id : null

  partner_solution_id            = each.value.partner_solution_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_metric" {
    for_each = each.value.metric != null ? each.value.metric : []
    iterator = enabled_metric

    content {
      category = enabled_metric.value.category
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.enabled_log != null ? each.value.enabled_log : []
    iterator = enabled_log
    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_storage_account.main,
    azurerm_key_vault.main,
    azurerm_mysql_flexible_server.main,
    azurerm_public_ip.main,
    azurerm_log_analytics_workspace.main,
    azurerm_application_gateway.main
  ]
}
