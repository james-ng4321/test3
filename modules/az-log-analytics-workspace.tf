resource "azurerm_log_analytics_workspace" "main" {
  for_each = {
    for index, log_analytics_workspace in coalesce(var.log_analytics_workspaces, []) : log_analytics_workspace.name => log_analytics_workspace
  }
  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  allow_resource_only_permissions = each.value.allow_resource_only_permissions
  #   local_authentication_enabled    = each.value.local_authentication_enabled
  sku                  = each.value.sku
  retention_in_days    = each.value.retention_in_days
  daily_quota_gb       = each.value.daily_quota_gb
  cmk_for_query_forced = each.value.cmk_for_query_forced

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    iterator = identity
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  internet_ingestion_enabled              = each.value.internet_ingestion_enabled
  internet_query_enabled                  = each.value.internet_query_enabled
  reservation_capacity_in_gb_per_day      = each.value.reservation_capacity_in_gb_per_day
  data_collection_rule_id                 = each.value.data_collection_rule_id
  immediate_data_purge_on_30_days_enabled = each.value.immediate_data_purge_on_30_days_enabled
  tags                                    = each.value.tags
}
