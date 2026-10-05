resource "azurerm_subnet" "main" {
  for_each = {
    for subnet_name, virtual_network_subnet in local.virtual_network_subnets : virtual_network_subnet.subnet.name => virtual_network_subnet
  }
  resource_group_name               = each.value.resource_group_name
  virtual_network_name              = each.value.virtual_network_name
  name                              = each.value.subnet.name
  address_prefixes                  = [each.value.subnet.address_prefix]
  private_endpoint_network_policies = coalesce(each.value.subnet.private_endpoint_network_policies, "Enabled")
  service_endpoints                 = coalesce(each.value.subnet.service_endpoints, [])

  dynamic "delegation" {
    for_each = coalesce(each.value.subnet.delegations, [])
    iterator = delegation

    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.main
  ]
}
