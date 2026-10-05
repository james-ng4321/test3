resource "azurerm_container_registry" "main" {
  for_each = {
    for acr in coalesce(var.container_registries, []) : acr.name => acr
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  admin_enabled       = coalesce(each.value.admin_enabled, false)

  public_network_access_enabled = coalesce(each.value.public_network_access_enabled, true)
  zone_redundancy_enabled       = coalesce(each.value.zone_redundancy_enabled, false)
  export_policy_enabled         = coalesce(each.value.export_policy_enabled, true)
  quarantine_policy_enabled     = coalesce(each.value.quarantine_policy_enabled, false)
  retention_policy_in_days      = each.value.retention_policy_in_days
  trust_policy_enabled          = coalesce(each.value.trust_policy_enabled, false)
  data_endpoint_enabled         = coalesce(each.value.data_endpoint_enabled, false)
  network_rule_bypass_option    = coalesce(each.value.network_rule_bypass_option, "AzureServices")

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  dynamic "network_rule_set" {
    for_each = each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = coalesce(network_rule_set.value.ip_rules, [])
        content {
          action   = "Allow"
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }

  dynamic "georeplications" {
    for_each = coalesce(each.value.georeplications, [])
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = coalesce(georeplications.value.zone_redundancy_enabled, false)
      regional_endpoint_enabled = coalesce(georeplications.value.regional_endpoint_enabled, false)
      tags                      = georeplications.value.tags
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Private Endpoint for Container Registry
resource "azurerm_private_endpoint" "container_registry" {
  for_each = {
    for private_endpoint in coalesce(flatten([
      for acr in coalesce(var.container_registries, []) : [
        for private_endpoint in coalesce(acr.private_endpoints, []) : merge(private_endpoint, {
          acr_name            = acr.name
          resource_group_name = acr.resource_group_name
          location            = acr.location
        })
      ]
    ]), []) : "${private_endpoint.acr_name}-${private_endpoint.name}" => private_endpoint
  }

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = azurerm_subnet.main[each.value.subnet_name].id
  custom_network_interface_name = each.value.custom_network_interface_name

  private_service_connection {
    name                           = "${each.value.name}-connection"
    private_connection_resource_id = azurerm_container_registry.main[each.value.acr_name].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration != null ? [each.value.ip_configuration] : []
    content {
      name               = "ipconfig1"
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = "registry"
      member_name        = each.value.member_name
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_names != null ? [1] : []
    content {
      name                 = "${each.value.name}-dns-zone-group"
      private_dns_zone_ids = [for private_dns_zone_name in each.value.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_container_registry.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}

# Grant AcrPush role to specified managed identities
resource "azurerm_role_assignment" "acr_push" {
  for_each = {
    for item in coalesce(flatten([
      for acr in coalesce(var.container_registries, []) : [
        for identity_name in coalesce(acr.acr_push_identity_names, []) : {
          acr_name      = acr.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${item.acr_name}-${item.identity_name}" => item
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "AcrPush"
  scope                            = azurerm_container_registry.main[each.value.acr_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_container_registry.main,
    azurerm_user_assigned_identity.main
  ]
}

resource "azurerm_role_assignment" "acr_push_principal" {
  for_each = {
    for item in coalesce(flatten([
      for acr in coalesce(var.container_registries, []) : [
        for principal_id in coalesce(acr.acr_push_principal_ids, []) : {
          acr_name     = acr.name
          principal_id = principal_id
        }
      ]
    ]), []) : "${item.acr_name}-${item.principal_id}" => item
  }

  principal_id                     = each.value.principal_id
  role_definition_name             = "AcrPush"
  scope                            = azurerm_container_registry.main[each.value.acr_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_container_registry.main
  ]
}
