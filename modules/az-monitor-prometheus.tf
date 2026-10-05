# ---------------------------------------------------------------------------
# Prometheus Data Collection Rule + Endpoint + Association
#
# When monitor_metrics is enabled on AKS, Azure provisions a metrics addon.
# A DCR + DCE linked to an Azure Monitor Workspace routes scraped
# Prometheus metrics to the correct backend.
#
# Enabled per AKS cluster via: enable_prometheus = true
# Requires: monitor_workspace_name (Azure Monitor Workspace for Prometheus)
# ---------------------------------------------------------------------------

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_prometheus, false) && aks.monitor_workspace_name != null
  }

  name                          = each.value.prometheus_dce_name != null ? each.value.prometheus_dce_name : replace(each.value.name, "-AKS-", "-DCE-PROM-")
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  kind                          = "Linux"
  public_network_access_enabled = true

  depends_on = [
    azurerm_resource_group.main
  ]
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_prometheus, false) && aks.monitor_workspace_name != null
  }

  name                        = each.value.prometheus_dcr_name != null ? each.value.prometheus_dcr_name : replace(each.value.name, "-AKS-", "-DCR-PROM-")
  resource_group_name         = each.value.resource_group_name
  location                    = each.value.location
  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[each.key].id

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.main[each.value.monitor_workspace_name].id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  depends_on = [
    azurerm_monitor_workspace.main,
    azurerm_monitor_data_collection_endpoint.prometheus
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_prometheus, false) && aks.monitor_workspace_name != null
  }

  name                    = "MSProm-${each.value.resource_group_name}-${each.value.name}"
  target_resource_id      = azurerm_kubernetes_cluster.main[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus[each.key].id

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_monitor_data_collection_rule.prometheus
  ]
}
