resource "azurerm_automation_account" "main" {
  for_each = {
    for automation_account_name, automation_account in coalesce(var.automation_accounts, []) : automation_account.name => automation_account
  }
  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  sku_name                      = each.value.sku_name
  local_authentication_enabled  = each.value.local_authentication_enabled
  public_network_access_enabled = each.value.public_network_access_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    iterator = identity

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_identity != null ? azurerm_user_assigned_identity.main[identity.value.user_assigned_identity].id : null
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    iterator = encryption

    content {
      key_vault_key_id          = azurerm_key_vault.main[encryption.value.key_vault_key_name].id
      user_assigned_identity_id = encryption.value.user_assigned_identity != null ? azurerm_user_assigned_identity.main[encryption.value.user_assigned_identity].id : null
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

resource "azurerm_automation_schedule" "main" {
  for_each = {
    for index, automation_schedule in coalesce(flatten([
      for index, automation_account in coalesce(var.automation_accounts, []) : [
        for index, automation_schedule in coalesce(automation_account.automation_schedules, []) : merge(automation_schedule, {
          resource_group_name     = automation_account.resource_group_name
          automation_account_name = automation_account.name
        })
      ]
    ]), []) : automation_schedule.name => automation_schedule
  }

  name                    = each.value.name
  resource_group_name     = each.value.resource_group_name
  automation_account_name = each.value.automation_account_name
  frequency               = each.value.frequency
  description             = each.value.description
  interval                = each.value.interval
  start_time              = each.value.start_time
  expiry_time             = each.value.expiry_time
  timezone                = each.value.timezone
  week_days               = each.value.week_days
  month_days              = each.value.month_days
  dynamic "monthly_occurrence" {
    for_each = each.value.monthly_occurrence != null ? [each.value.monthly_occurrence] : []
    iterator = monthly_occurrence

    content {
      day        = monthly_occurrence.day
      occurrence = monthly_occurrence.occurrence
    }
  }

  depends_on = [
    azurerm_automation_account.main
  ]

}

data "local_file" "Auto_Start_AzVM" {
  filename = "${path.module}/AutoStartAzVM.ps1"
}

resource "azurerm_automation_runbook" "main" {
  for_each = {
    for index, automation_runbook in coalesce(flatten([
      for automation_account_name, automation_account in coalesce(var.automation_accounts, []) : [
        for automation_runbook_name, automation_runbook in coalesce(automation_account.automation_runbooks, []) : merge(automation_runbook, {
          automation_account_name = automation_account.name
          resource_group_name     = automation_account.resource_group_name
          location                = automation_account.location
        })
      ]
    ]), []) : automation_runbook.name => automation_runbook
  }

  name                    = each.value.name
  location                = each.value.location
  resource_group_name     = each.value.resource_group_name
  automation_account_name = each.value.automation_account_name
  log_verbose             = each.value.log_verbose
  log_progress            = each.value.log_progress

  dynamic "publish_content_link" {
    for_each = each.value.publish_content_link != null ? [each.value.publish_content_link] : []
    iterator = publish_content_link

    content {
      uri     = publish_content_link.value.uri
      version = publish_content_link.value.version

      dynamic "hash" {
        for_each = publish_content_link.value.hash != null ? [publish_content_link.value.hash] : []
        iterator = hash

        content {
          algorithm = hash.value.algorithm
          value     = hash.value.value
        }
      }
    }
  }

  description              = each.value.description
  runbook_type             = each.value.runbook_type
  content                  = data.local_file.Auto_Start_AzVM.content
  tags                     = each.value.tags
  log_activity_trace_level = each.value.log_activity_trace_level

  dynamic "draft" {
    for_each = each.value.draft != null ? [each.value.draft] : []
    iterator = draft

    content {
      edit_mode_enabled = draft.value.edit_mode_enabled

      dynamic "content_link" {
        for_each = each.value.content_link != null ? [each.value.content_link] : []
        iterator = content_link
        content {
          uri     = content_link.value.uri
          version = content_link.value.version

          dynamic "hash" {
            for_each = content_link.value.hash != null ? [content_link.value.hash] : []
            iterator = hash

            content {
              algorithm = hash.value.algorithm
              value     = hash.value.value
            }
          }
        }
      }

      output_types = draft.output_types

      dynamic "parameters" {
        for_each = each.value.parameters != null ? [each.value.parameters] : []
        iterator = parameters

        content {
          key           = parameters.value.key
          type          = parameters.value.type
          mandatory     = parameters.value.mandatory
          position      = parameters.value.position
          default_value = parameters.value.default_value
        }
      }
    }
  }
  dynamic "job_schedule" {
    for_each = each.value.job_schedules != null ? each.value.job_schedules : []
    iterator = job_schedule

    content {
      schedule_name = job_schedule.value.schedule_name
      parameters    = job_schedule.value.parameters
      run_on        = job_schedule.value.run_on
    }
  }
  depends_on = [
    azurerm_automation_account.main,
    azurerm_automation_schedule.main
  ]
}
