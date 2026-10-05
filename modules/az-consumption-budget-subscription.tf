data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "main" {
  for_each = {
    for index, consumption_budget_subscription in coalesce(var.consumption_budget_subscription, []) : consumption_budget_subscription.name => consumption_budget_subscription
  }

  name            = each.value.name
  subscription_id = data.azurerm_subscription.current.id
  amount          = each.value.amount
  time_grain      = each.value.time_grain
  time_period {
    start_date = each.value.time_period.start_date
    end_date   = each.value.time_period.end_date
  }

  dynamic "notification" {
    for_each = each.value.notifications != null ? each.value.notifications : []
    iterator = notification
    content {
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_groups = notification.value.contact_groups
      contact_roles  = notification.value.contact_roles
      enabled        = notification.value.enabled
    }
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    iterator = filter
    content {
      dynamic "dimension" {
        for_each = filter.value.dimensions != null ? filter.value.dimensions : []
        iterator = dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
      dynamic "tag" {
        for_each = filter.value.tags != null ? filter.value.tags : []
        iterator = tag
        content {
          name     = tag.value.name
          operator = tag.value.operator
          values   = tag.value.values
        }
      }
    }
  }
}
