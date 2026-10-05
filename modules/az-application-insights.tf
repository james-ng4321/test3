# ---------------------------------------------------------------------------
# Application Insights (workspace-based)
#
# Wraps azurerm_application_insights. Each entry is backed by an existing
# Log Analytics workspace (resolved by name from this module, or an explicit
# workspace_id). The component's Connection String is what the application
# (e.g. a .NET app via the Azure Monitor OpenTelemetry distro) uses to send
# request/dependency/exception/trace telemetry.
# ---------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  for_each = {
    for ai in coalesce(var.application_insights, []) : ai.name => ai
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  application_type    = each.value.application_type

  workspace_id = (
    each.value.workspace_id != null ? each.value.workspace_id :
    azurerm_log_analytics_workspace.main[each.value.log_analytics_workspace_name].id
  )

  sampling_percentage           = each.value.sampling_percentage
  retention_in_days             = each.value.retention_in_days
  daily_data_cap_in_gb          = each.value.daily_data_cap_in_gb
  internet_ingestion_enabled    = each.value.internet_ingestion_enabled
  internet_query_enabled        = each.value.internet_query_enabled
  local_authentication_disabled = each.value.local_authentication_disabled

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_log_analytics_workspace.main
  ]
}
