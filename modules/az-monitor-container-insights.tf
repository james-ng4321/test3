# ---------------------------------------------------------------------------
# Container Insights Data Collection Rule (DCR)
#
# Required when oms_agent uses MSI auth (msi_auth_for_monitoring_enabled=true).
# Without a DCR linked to the cluster, the OMS agent runs but cannot send
# ContainerLogV2 / KubePodInventory / KubeEvents to Log Analytics.
#
# Enabled per AKS cluster via: enable_container_insights = true
# Workspace is derived from: oms_agent.log_analytics_workspace_id
# ---------------------------------------------------------------------------

resource "azurerm_monitor_data_collection_rule" "container_insights" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_container_insights, false) && aks.oms_agent != null && aks.oms_agent.log_analytics_workspace_id != null
  }

  name                = each.value.container_insights_dcr_name != null ? each.value.container_insights_dcr_name : replace(each.value.name, "-AKS-", "-DCR-AKS-")
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = each.value.oms_agent.log_analytics_workspace_id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = coalesce(each.value.container_insights_interval, "5m")
          namespaceFilteringMode = each.value.container_insights_exclude_namespaces != null ? "Exclude" : "Off"
          namespaces             = coalesce(each.value.container_insights_exclude_namespaces, [])
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = each.value.tags
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.enable_container_insights, false) && aks.oms_agent != null && aks.oms_agent.log_analytics_workspace_id != null
  }

  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.main[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights[each.key].id

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_monitor_data_collection_rule.container_insights
  ]
}
