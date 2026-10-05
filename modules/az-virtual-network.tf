resource "azurerm_virtual_network" "main" {
  for_each = {
    for virtual_network_name, virtual_network in coalesce(var.virtual_networks, []) : virtual_network.name => virtual_network
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}
