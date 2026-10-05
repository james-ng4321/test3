# ---------------------------------------------------------------------------
# VM Insights — Azure Monitor Linux Agent + Data Collection Rule
#
# For each entry in var.linux_vm_monitoring_agents, this module:
#   1. Installs the AzureMonitorLinuxAgent VM extension on the target VM.
#   2. Creates a DCR that streams Linux performance counters
#      (Logical Disk, Memory, Processor, Network) into Log Analytics.
#   3. Associates the DCR to the VM so the agent knows what to collect.
#
# Required for filesystem free space alerts (Logical Disk\% Used Space) and
# any other guest-OS metric that Azure platform metrics don't expose.
# ---------------------------------------------------------------------------

resource "azurerm_virtual_machine_extension" "azure_monitor_linux_agent" {
  for_each = {
    for agent in coalesce(var.linux_vm_monitoring_agents, []) : agent.linux_virtual_machine_name => agent
    if coalesce(agent.enabled, true)
  }

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main[each.value.linux_virtual_machine_name].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.33"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  # Use User-Assigned identity for AMA only when explicitly requested.
  # Otherwise the agent falls back to the VM's System-Assigned identity.
  settings = (
    each.value.identity_type == "UserAssigned" && each.value.user_assigned_identity_name != null
    ? jsonencode({
      authentication = {
        managedIdentity = {
          "identifier-name"  = "mi_res_id"
          "identifier-value" = azurerm_user_assigned_identity.main[each.value.user_assigned_identity_name].id
        }
      }
    })
    : null
  )

  depends_on = [
    azurerm_linux_virtual_machine.main
  ]
}

resource "azurerm_monitor_data_collection_rule" "linux_vm_insights" {
  for_each = {
    for agent in coalesce(var.linux_vm_monitoring_agents, []) : agent.linux_virtual_machine_name => agent
    if coalesce(agent.enabled, true)
  }

  name                = each.value.dcr_name != null ? each.value.dcr_name : "${each.value.linux_virtual_machine_name}-DCR"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  kind                = "Linux"
  description         = "Linux perf counters + syslog for ${each.value.linux_virtual_machine_name}"

  destinations {
    log_analytics {
      workspace_resource_id = (
        each.value.log_analytics_workspace_id != null ? each.value.log_analytics_workspace_id :
        azurerm_log_analytics_workspace.main[each.value.log_analytics_workspace_name].id
      )
      name = "la-dest"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["la-dest"]
  }

  dynamic "data_flow" {
    for_each = coalesce(each.value.collect_syslog, false) ? [1] : []
    content {
      streams      = ["Microsoft-Syslog"]
      destinations = ["la-dest"]
    }
  }

  data_sources {
    performance_counter {
      name                          = "perfCounterDataSource"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = coalesce(each.value.sampling_frequency_in_seconds, 60)
      counter_specifiers = coalesce(each.value.counter_specifiers, [
        "\\Processor(*)\\% Processor Time",
        "\\Memory\\% Used Memory",
        "\\Memory\\Available MBytes Memory",
        "\\Logical Disk(*)\\% Used Space",
        "\\Logical Disk(*)\\% Used Inodes",
        "\\Logical Disk(*)\\Free Megabytes",
        "\\Logical Disk(*)\\Disk Read Bytes/sec",
        "\\Logical Disk(*)\\Disk Write Bytes/sec",
        "\\Logical Disk(*)\\Disk Reads/sec",
        "\\Logical Disk(*)\\Disk Writes/sec",
        "\\Network\\Total Bytes Received",
        "\\Network\\Total Bytes Transmitted"
      ])
    }

    dynamic "syslog" {
      for_each = coalesce(each.value.collect_syslog, false) ? [1] : []
      content {
        name           = "sysLogsDataSource"
        streams        = ["Microsoft-Syslog"]
        facility_names = coalesce(each.value.syslog_facility_names, ["auth", "authpriv", "cron", "daemon", "kern", "syslog", "user"])
        log_levels     = coalesce(each.value.syslog_log_levels, ["Warning", "Error", "Critical", "Alert", "Emergency"])
      }
    }
  }

  tags = each.value.tags
}

resource "azurerm_monitor_data_collection_rule_association" "linux_vm_insights" {
  for_each = {
    for agent in coalesce(var.linux_vm_monitoring_agents, []) : agent.linux_virtual_machine_name => agent
    if coalesce(agent.enabled, true)
  }

  name                    = "linux-vm-insights"
  target_resource_id      = azurerm_linux_virtual_machine.main[each.value.linux_virtual_machine_name].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux_vm_insights[each.key].id

  depends_on = [
    azurerm_linux_virtual_machine.main,
    azurerm_monitor_data_collection_rule.linux_vm_insights,
    azurerm_virtual_machine_extension.azure_monitor_linux_agent
  ]
}
