resource "azurerm_data_protection_backup_policy_blob_storage" "main" {
  for_each = {
    for data_protection_backup_policy_blob_storage in coalesce(var.data_protection_backup_policies_blob_storage, []) : data_protection_backup_policy_blob_storage.name => data_protection_backup_policy_blob_storage
  }

  name                                   = each.value.name
  vault_id                               = each.value.vault_id != null ? each.value.vault_id : azurerm_data_protection_backup_vault.main[each.value.vault_name].id
  backup_repeating_time_intervals        = each.value.backup_repeating_time_intervals
  operational_default_retention_duration = each.value.operational_default_retention_duration

  dynamic "retention_rule" {
    for_each = each.value.retention_rule != null ? each.value.retention_rule : []
    iterator = retention_rule
    content {
      name = retention_rule.value.name
      criteria {
        absolute_criteria      = retention_rule.value.criteria.absolute_criteria
        days_of_month          = retention_rule.value.criteria.days_of_month
        days_of_week           = retention_rule.value.criteria.days_of_week
        months_of_year         = retention_rule.value.criteria.months_of_year
        scheduled_backup_times = retention_rule.value.criteria.scheduled_backup_times
        weeks_of_month         = retention_rule.value.criteria.weeks_of_month
      }

      life_cycle {
        data_store_type = retention_rule.value.life_cycle.data_store_type
        duration        = retention_rule.value.life_cycle.duration
      }

      priority = retention_rule.value.priority
    }
  }
  time_zone                        = each.value.time_zone
  vault_default_retention_duration = each.value.vault_default_retention_duration

  depends_on = [
    azurerm_data_protection_backup_vault.main
  ]
}

data "azurerm_storage_containers" "containers" {
  for_each = {
    for data_protection_backup_instance_blob_storage in coalesce(var.data_protection_backup_instances_blob_storage, []) : data_protection_backup_instance_blob_storage.name => data_protection_backup_instance_blob_storage
  }
  storage_account_id = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.main[each.value.storage_account_name].id
}

resource "azurerm_data_protection_backup_instance_blob_storage" "main" {
  for_each = {
    for data_protection_backup_instance_blob_storage in coalesce(var.data_protection_backup_instances_blob_storage, []) : data_protection_backup_instance_blob_storage.name => data_protection_backup_instance_blob_storage
  }
  name                            = each.value.name
  location                        = each.value.location
  vault_id                        = each.value.vault_id != null ? each.value.vault_id : azurerm_data_protection_backup_vault.main[each.value.vault_name].id
  storage_account_id              = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.main[each.value.storage_account_name].id
  backup_policy_id                = each.value.backup_policy_id != null ? each.value.backup_policy_id : azurerm_data_protection_backup_policy_blob_storage.main[each.value.backup_policy_name].id
  storage_account_container_names = each.value.storage_account_container_names != null ? each.value.storage_account_container_names : data.azurerm_storage_containers.containers[each.value.name].containers[*].name
}
