resource "azurerm_resource_group" "main" {
  for_each = {
    for resource_group_name, resource_group in coalesce(var.resource_groups, []) : resource_group.name => resource_group
  }
  name       = each.value.name
  location   = each.value.location
  managed_by = each.value.managed_by

  tags = each.value.tags
}
