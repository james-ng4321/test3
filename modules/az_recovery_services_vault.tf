resource "azurerm_recovery_services_vault" "main" {
  for_each = {
    for index, recovery_services_vault in coalesce(var.recovery_services_vaults, []) : recovery_services_vault.name => recovery_services_vault
  }
  name                               = each.value.name
  location                           = each.value.location
  resource_group_name                = each.value.resource_group_name
  sku                                = each.value.sku
  public_network_access_enabled      = each.value.public_network_access_enabled
  immutability                       = each.value.immutability
  storage_mode_type                  = each.value.storage_mode_type
  cross_region_restore_enabled       = each.value.cross_region_restore_enabled
  soft_delete_enabled                = each.value.soft_delete_enabled
  classic_vmware_replication_enabled = each.value.classic_vmware_replication_enabled


  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    iterator = encryption
    content {
      key_id                            = encryption.value.key_id
      infrastructure_encryption_enabled = encryption.value.infrastructure_encryption_enabled
      user_assigned_identity_id         = encryption.value.user_assigned_identity_id
      use_system_assigned_identity      = encryption.value.use_system_assigned_identity
    }
  }
  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = each.value.identity.type
      identity_ids = each.value.identity.identity_ids
    }
  }
  dynamic "monitoring" {
    for_each = each.value.monitoring == null ? [] : [1]
    content {
      alerts_for_all_job_failures_enabled            = each.value.monitoring.alerts_for_all_job_failures_enabled
      alerts_for_critical_operation_failures_enabled = each.value.monitoring.alerts_for_critical_operation_failures_enabled
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}


resource "azurerm_backup_policy_vm" "main" {
  for_each = {
    for index, backup_policy_vm in coalesce(flatten([
      for index, recovery_services_vault in coalesce(var.recovery_services_vaults, []) : [
        for index, backup_policy_vm in coalesce(recovery_services_vault.backup_policy_vm, []) : merge(backup_policy_vm, {
          resource_group_name = recovery_services_vault.resource_group_name
          recovery_vault_name = recovery_services_vault.name
        })
      ]
    ]), []) : backup_policy_vm.name => backup_policy_vm
  }
  name                           = each.value.name
  resource_group_name            = each.value.resource_group_name
  recovery_vault_name            = each.value.recovery_vault_name
  policy_type                    = each.value.policy_type
  timezone                       = each.value.timezone
  instant_restore_retention_days = each.value.instant_restore_retention_days

  dynamic "backup" {
    for_each = each.value.backup != null ? [each.value.backup] : []
    iterator = backup
    content {
      frequency     = backup.value.frequency
      time          = backup.value.time
      hour_interval = backup.value.hour_interval
      hour_duration = backup.value.hour_duration
    }
  }

  dynamic "retention_daily" {
    for_each = each.value.retention_daily != null ? [each.value.retention_daily] : []
    iterator = retention_daily
    content {
      count = retention_daily.value.count
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.retention_weekly != null ? [each.value.retention_weekly] : []
    iterator = retention_weekly
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.retention_monthly != null ? [each.value.retention_monthly] : []
    iterator = retention_monthly
    content {
      count             = retention_monthly.value.count
      weekdays          = retention_monthly.value.weekdays
      weeks             = retention_monthly.value.weeks
      days              = retention_monthly.value.days
      include_last_days = retention_monthly.value.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.retention_yearly != null ? [each.value.retention_yearly] : []
    iterator = retention_yearly
    content {
      count             = retention_yearly.value.count
      months            = retention_yearly.value.months
      weekdays          = retention_yearly.value.weekdays
      weeks             = retention_yearly.value.weeks
      days              = retention_yearly.value.days
      include_last_days = retention_yearly.value.include_last_days
    }
  }

  dynamic "instant_restore_resource_group" {
    for_each = each.value.instant_restore_resource_group != null ? [each.value.instant_restore_resource_group] : []
    iterator = instant_restore_resource_group
    content {
      prefix = instant_restore_resource_group.value.count
      suffix = instant_restore_resource_group.value.suffix
    }
  }
  depends_on = [
    azurerm_recovery_services_vault.main
  ]
}
