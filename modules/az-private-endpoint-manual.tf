resource "azurerm_private_endpoint" "mongo_private_endpoint" {
  for_each = {
    for pe in coalesce(var.mongo_private_endpoints, []) : pe.name => pe
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  subnet_id           = azurerm_subnet.main[each.value.subnet_name].id
  tags                = each.value.tags

  private_service_connection {
    name                           = each.value.private_connection_name
    private_connection_resource_id = each.value.private_connection_resource_id
    is_manual_connection           = each.value.is_manual_connection
    subresource_names              = each.value.subresource_names
    request_message                = each.value.request_message
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_names != null && length(each.value.private_dns_zone_names) > 0 ? [1] : []

    content {
      name = "${each.value.name}-dns-zone-group"
      private_dns_zone_ids = [
        for dns_zone_name in each.value.private_dns_zone_names :
        azurerm_private_dns_zone.main[dns_zone_name].id
      ]
    }
  }

  depends_on = [
    azurerm_subnet.main
  ]
}
