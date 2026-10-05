resource "azurerm_route_table" "main" {
  for_each = {
    for subnet_name, virtual_network_subnet in local.virtual_network_subnets : virtual_network_subnet.subnet.route_table.name => virtual_network_subnet
    if virtual_network_subnet.subnet.route_table != null
  }
  name                = each.value.subnet.route_table.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  bgp_route_propagation_enabled = each.value.subnet.route_table.bgp_route_propagation_enabled != null ? each.value.subnet.route_table.bgp_route_propagation_enabled : false

  dynamic "route" {
    for_each = {
      for route_name, route in coalesce(each.value.subnet.route_table.routes, []) : route.name => route
    }
    iterator = route

    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}


resource "azurerm_subnet_route_table_association" "main" {
  for_each = {
    for subnet_name, virtual_network_subnet in local.virtual_network_subnets : virtual_network_subnet.subnet.route_table.name => virtual_network_subnet
    if virtual_network_subnet.subnet.route_table != null
  }
  subnet_id      = azurerm_subnet.main[each.value.subnet.name].id
  route_table_id = azurerm_route_table.main[each.value.subnet.route_table.name].id

  depends_on = [
    azurerm_subnet.main,
    azurerm_route_table.main
  ]
}