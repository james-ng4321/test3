resource "azurerm_private_dns_zone" "main" {
  for_each = {
    for private_dns_zone_name, private_dns_zone in var.private_dns_zones : private_dns_zone.name => private_dns_zone
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []
    iterator = soa_record

    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
      tags         = soa_record.value.tags
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

resource "azurerm_private_dns_a_record" "main" {
  for_each = {
    for index, private_dns_a_record in coalesce(flatten([
      for index, private_dns_zone in coalesce(var.private_dns_zones, []) : [
        for index, private_dns_a_record in coalesce(private_dns_zone.a_records, []) : merge(
          private_dns_a_record,
          {
            private_dns_zone_name                = private_dns_zone.name,
            private_dns_zone_resource_group_name = private_dns_zone.resource_group_name
          }
        )
      ]
    ])) : private_dns_a_record.name => private_dns_a_record
  }
  name                = each.value.name
  resource_group_name = each.value.private_dns_zone_resource_group_name
  zone_name           = each.value.private_dns_zone_name
  ttl                 = each.value.ttl
  records             = each.value.records
}

# resource "azurerm_private_dns_aaaa_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.aaaa_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl     = each.value.ttl
#   records = each.value.records

#   tags = each.value.tags
# }

# resource "azurerm_private_dns_cname_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.cname_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl    = each.value.ttl
#   record = each.value.record

#   tags = each.value.tags
# }

# resource "azurerm_private_dns_mx_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.mx_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl = each.value.ttl

#   dynamic "record" {
#     for_each = { for index, r in each.value.records : index => r }

#     content {
#       preference = record.value.preference
#       exchange   = record.value.exchange
#     }
#   }

#   tags = each.value.tags
# }

# resource "azurerm_private_dns_ptr_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.ptr_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl     = each.value.ttl
#   records = each.value.records

#   tags = each.value.tags
# }

# resource "azurerm_private_dns_srv_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.srv_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl = each.value.ttl

#   dynamic "record" {
#     for_each = { for index, r in each.value.records : index => r }

#     content {
#       priority = record.value.priority
#       weight   = record.value.weight
#       port     = record.value.port
#       target   = record.value.target
#     }
#   }

#   tags = each.value.tags
# }

# resource "azurerm_private_dns_txt_record" "main" {
#   for_each = { for index, rec in coalesce(var.azure_private_dns_zone.txt_records, []) : rec.name => rec }

#   name                = each.value.name
#   resource_group_name = azurerm_private_dns_zone.main.resource_group_name
#   zone_name           = azurerm_private_dns_zone.main.name

#   ttl = each.value.ttl

#   dynamic "record" {
#     for_each = { for index, r in each.value.records : index => r }

#     content {
#       value = record.value.value
#     }
#   }

#   tags = each.value.tags
# }

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = { for index, virtual_network_link in coalesce(flatten([
    for index, private_dns_zone in var.private_dns_zones : [
      for index, virtual_network_link in coalesce(private_dns_zone.virtual_network_links, []) : merge(virtual_network_link, {
        private_dns_zone_name                = private_dns_zone.name
        private_dns_zone_resource_group_name = private_dns_zone.resource_group_name
      })
    ]
  ]), []) : "${virtual_network_link.private_dns_zone_name}.${virtual_network_link.name}" => virtual_network_link }

  name                  = each.value.name
  private_dns_zone_name = each.value.private_dns_zone_name
  resource_group_name   = each.value.private_dns_zone_resource_group_name
  virtual_network_id    = each.value.virtual_network_id != null ? each.value.virtual_network_id : azurerm_virtual_network.main[each.value.virtual_network_name].id
  registration_enabled  = each.value.registration_enabled
  tags                  = each.value.tags

  depends_on = [
    azurerm_virtual_network.main,
    azurerm_private_dns_zone.main
  ]
}
