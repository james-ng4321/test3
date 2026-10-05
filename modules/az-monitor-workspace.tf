resource "azurerm_monitor_workspace" "main" {
  for_each = {
    for ws in coalesce(var.monitor_workspaces, []) : ws.name => ws
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}
