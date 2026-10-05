resource "azurerm_user_assigned_identity" "main" {
  for_each = {
    for index, user_assigned_identity in coalesce(var.user_assigned_identities, []) : user_assigned_identity.name => user_assigned_identity
  }

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Grant Reader role to AKS identities for Resource Group access
# This allows Azure CLI commands (az aks get-credentials) to work from VMs
resource "azurerm_role_assignment" "identity_reader" {
  for_each = {
    for identity in coalesce(var.user_assigned_identities, []) : identity.name => identity
    if identity.grant_reader_role == true
  }

  principal_id         = azurerm_user_assigned_identity.main[each.key].principal_id
  role_definition_name = "Reader"
  scope                = azurerm_resource_group.main[each.value.resource_group_name].id

  depends_on = [
    azurerm_user_assigned_identity.main,
    azurerm_resource_group.main
  ]
}
