resource "azurerm_network_security_group" "main" {
  for_each = {
    for subnet_name, virtual_network_subnet in local.virtual_network_subnets : virtual_network_subnet.subnet.network_security_group.name => virtual_network_subnet
    if virtual_network_subnet.subnet.network_security_group != null
  }
  name                = each.value.subnet.network_security_group.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  dynamic "security_rule" {
    for_each = {
      for rule_name, rule in coalesce(each.value.subnet.network_security_group.rules, []) : rule.name => rule
    }
    iterator = security_rule

    content {
      name                                       = security_rule.value.name
      priority                                   = security_rule.value.priority
      direction                                  = security_rule.value.direction
      access                                     = security_rule.value.access
      protocol                                   = security_rule.value.protocol
      description                                = security_rule.value.description
      source_address_prefix                      = security_rule.value.source_address_prefix
      source_address_prefixes                    = security_rule.value.source_address_prefixes
      source_port_range                          = security_rule.value.source_port_range
      source_port_ranges                         = security_rule.value.source_port_ranges
      source_application_security_group_ids      = security_rule.value.source_application_security_group_ids
      destination_address_prefix                 = security_rule.value.destination_address_prefix
      destination_address_prefixes               = security_rule.value.destination_address_prefixes
      destination_port_range                     = security_rule.value.destination_port_range
      destination_port_ranges                    = security_rule.value.destination_port_ranges
      destination_application_security_group_ids = security_rule.value.destination_application_security_group_ids
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}


resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = {
    for subnet_name, virtual_network_subnet in local.virtual_network_subnets : virtual_network_subnet.subnet.network_security_group.name => virtual_network_subnet
  }
  subnet_id                 = azurerm_subnet.main[each.value.subnet.name].id
  network_security_group_id = azurerm_network_security_group.main[each.value.subnet.network_security_group.name].id

  depends_on = [
    azurerm_network_security_group.main,
    azurerm_subnet.main
  ]
}
