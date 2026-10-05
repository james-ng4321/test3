resource "azurerm_data_protection_backup_vault" "main" {
  for_each = {
    for data_protection_backup_vault in coalesce(var.data_protection_backup_vaults, []) : data_protection_backup_vault.name => data_protection_backup_vault
  }
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  datastore_type               = each.value.datastore_type
  redundancy                   = each.value.redundancy
  cross_region_restore_enabled = each.value.cross_region_restore_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
    }
  }

  retention_duration_in_days = each.value.retention_duration_in_days
  immutability               = each.value.immutability
  soft_delete                = each.value.soft_delete
  tags                       = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}
