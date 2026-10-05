resource "azurerm_dev_test_global_vm_shutdown_schedule" "main" {
  for_each = {
    for index, vm_shutdown_schedule in coalesce(var.vm_shutdown_schedules, []) : vm_shutdown_schedule.virtual_machine_name => vm_shutdown_schedule
  }
  location              = each.value.location
  virtual_machine_id    = azurerm_windows_virtual_machine.main[each.value.virtual_machine_name].id
  enabled               = each.value.enabled
  timezone              = each.value.timezone
  daily_recurrence_time = each.value.daily_recurrence_time

  notification_settings {
    enabled         = each.value.notification_settings.enabled
    email           = each.value.notification_settings.email
    time_in_minutes = each.value.notification_settings.time_in_minutes
    webhook_url     = each.value.notification_settings.webhook_url
  }

  tags = each.value.tags
}