resource "azurerm_dashboard_grafana" "main" {
  for_each = {
    for g in coalesce(var.dashboard_grafanas, []) : g.name => g
  }

  name                              = each.value.name
  resource_group_name               = each.value.resource_group_name
  location                          = each.value.location
  sku                               = coalesce(each.value.sku, "Standard")
  zone_redundancy_enabled           = coalesce(each.value.zone_redundancy_enabled, false)
  api_key_enabled                   = coalesce(each.value.api_key_enabled, false)
  deterministic_outbound_ip_enabled = coalesce(each.value.deterministic_outbound_ip_enabled, false)
  public_network_access_enabled     = coalesce(each.value.public_network_access_enabled, true)
  grafana_major_version             = coalesce(each.value.grafana_major_version, 10)

  identity {
    type = "SystemAssigned"
  }

  dynamic "azure_monitor_workspace_integrations" {
    for_each = coalesce(each.value.azure_monitor_workspace_names, [])
    content {
      resource_id = azurerm_monitor_workspace.main[azure_monitor_workspace_integrations.value].id
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_monitor_workspace.main
  ]
}

# Grant Grafana's managed identity "Monitoring Reader" on the subscription
# so it can read metrics from Azure Monitor Workspace (Prometheus) and Log Analytics
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  for_each = {
    for g in coalesce(var.dashboard_grafanas, []) : g.name => g
  }

  principal_id                     = azurerm_dashboard_grafana.main[each.key].identity[0].principal_id
  role_definition_name             = "Monitoring Reader"
  scope                            = "/subscriptions/${var.subscription_id}"
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_dashboard_grafana.main
  ]
}

# Grant Grafana's managed identity "Monitoring Data Reader" on each Azure Monitor Workspace
# for Prometheus data access
resource "azurerm_role_assignment" "grafana_monitor_workspace_reader" {
  for_each = {
    for item in coalesce(flatten([
      for g in coalesce(var.dashboard_grafanas, []) : [
        for ws_name in coalesce(g.azure_monitor_workspace_names, []) : {
          grafana_name   = g.name
          workspace_name = ws_name
        }
      ]
    ]), []) : "${item.grafana_name}-${item.workspace_name}" => item
  }

  principal_id                     = azurerm_dashboard_grafana.main[each.value.grafana_name].identity[0].principal_id
  role_definition_name             = "Monitoring Data Reader"
  scope                            = azurerm_monitor_workspace.main[each.value.workspace_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_dashboard_grafana.main,
    azurerm_monitor_workspace.main
  ]
}

# Grant Grafana admin access to specified users/groups
resource "azurerm_role_assignment" "grafana_admin" {
  for_each = {
    for item in coalesce(flatten([
      for g in coalesce(var.dashboard_grafanas, []) : [
        for principal_id in coalesce(g.grafana_admin_principal_ids, []) : {
          grafana_name = g.name
          principal_id = principal_id
        }
      ]
    ]), []) : "${item.grafana_name}-${item.principal_id}" => item
  }

  principal_id         = each.value.principal_id
  role_definition_name = "Grafana Admin"
  scope                = azurerm_dashboard_grafana.main[each.value.grafana_name].id

  depends_on = [
    azurerm_dashboard_grafana.main
  ]
}
