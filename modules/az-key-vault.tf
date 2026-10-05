resource "azurerm_key_vault" "main" {
  for_each = {
    for key_vault_name, key_vault in coalesce(var.key_vaults, []) : key_vault.name => key_vault
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku_name            = each.value.sku_name
  tenant_id           = var.tenant_id

  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_template_deployment = each.value.enabled_for_template_deployment
  rbac_authorization_enabled      = each.value.enable_rbac_authorization
  purge_protection_enabled        = each.value.purge_protection_enabled
  public_network_access_enabled   = each.value.public_network_access_enabled
  soft_delete_retention_days      = each.value.soft_delete_retention_days

  dynamic "network_acls" {
    for_each = each.value.network_acls != null ? [each.value.network_acls] : []
    iterator = network_acls

    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  dynamic "contact" {
    for_each = { for index, contact in coalesce(each.value.contacts, []) : contact.email => contact }

    content {
      email = each.value.email
      name  = each.value.name
      phone = each.value.phone
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

# To rotate: bump expiration_date in tfvars (and update the value in the TFC
# "key_vault_secret_values" variable), then run terraform apply.
resource "azurerm_key_vault_secret" "main" {
  # Only manage secrets whose value is present in the TFC map; others are
  # skipped (not overwritten) until their value is added.
  for_each = {
    for item in flatten([
      for kv in coalesce(var.key_vaults, []) : [
        for secret in coalesce(kv.secrets, []) : {
          kv_name = kv.name
          secret  = secret
        }
      ]
    ]) : "${item.kv_name}/${item.secret.name}" => item
    # keys() of the sensitive map is itself sensitive; the names aren't secret,
    # so unmark them to keep for_each keys non-sensitive.
    if contains(nonsensitive(keys(var.key_vault_secret_values)), item.secret.name)
  }

  name         = each.value.secret.name
  key_vault_id = azurerm_key_vault.main[each.value.kv_name].id
  value        = var.key_vault_secret_values[each.value.secret.name]

  content_type    = each.value.secret.content_type
  not_before_date = each.value.secret.not_before_date
  expiration_date = each.value.secret.expiration_date
  tags            = each.value.secret.tags

  depends_on = [
    azurerm_key_vault.main
  ]
}

# resource "azurerm_key_vault_key" "main" {
#   for_each = {
#     for key_vault_name, key_vault in var.key_vaults : key_vault.name => key_vault
#   }

#   name            = each.value.name
#   key_vault_id    = azurerm_key_vault.main.id
#   key_type        = each.value.key_type
#   key_size        = each.value.key_size
#   curve           = each.value.curve
#   key_opts        = each.value.key_opts
#   not_before_date = each.value.not_before_date
#   expiration_date = each.value.expiration_date
#   tags            = each.value.tags

#   dynamic "rotation_policy" {
#     for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []

#     content {
#       expire_after         = rotation_policy.value.expire_after
#       notify_before_expiry = rotation_policy.value.notify_before_expiry
#       dynamic "automatic" {
#         for_each = rotation_policy.value.automatic != null ? [rotation_policy.value.automatic] : []

#         content {
#           time_after_creation = automatic.value.time_after_creation
#           time_before_expiry  = automatic.value.time_before_expiry
#         }
#       }
#     }
#   }
# }

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  for_each = {
    for item in coalesce(flatten([
      for kv in coalesce(var.key_vaults, []) : [
        for identity_name in coalesce(kv.secrets_user_identity_names, []) : {
          kv_name       = kv.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${item.kv_name}-${item.identity_name}" => item
  }

  scope                = azurerm_key_vault.main[each.value.kv_name].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id

  depends_on = [
    azurerm_key_vault.main,
    azurerm_user_assigned_identity.main
  ]
}

resource "azurerm_role_assignment" "key_vault_secrets_user_aks_kubelet" {
  for_each = {
    for item in coalesce(flatten([
      for kv in coalesce(var.key_vaults, []) : [
        for aks_name in coalesce(kv.secrets_user_aks_kubelet_names, []) : {
          kv_name  = kv.name
          aks_name = aks_name
        }
      ]
    ]), []) : "${item.kv_name}-${item.aks_name}" => item
  }

  scope                            = azurerm_key_vault.main[each.value.kv_name].id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_kubernetes_cluster.main[each.value.aks_name].kubelet_identity[0].object_id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_key_vault.main,
    azurerm_kubernetes_cluster.main
  ]
}

resource "azurerm_private_endpoint" "key_vault" {
  for_each = { for index, private_endpoint in coalesce(flatten([
    for key_vault_name, key_vault in coalesce(var.key_vaults, []) : [
      for private_endpoint_name, private_endpoint in coalesce(key_vault.private_endpoints, []) : {
        key_vault_name      = key_vault.name
        resource_group_name = key_vault.resource_group_name
        location            = key_vault.location
        private_endpoint    = private_endpoint
      }
    ]
  ]), []) : private_endpoint.private_endpoint.name => private_endpoint }

  name                = each.value.private_endpoint.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  subnet_id                     = each.value.private_endpoint.subnet_id == null ? azurerm_subnet.main[each.value.private_endpoint.subnet_name].id : each.value.private_endpoint.subnet_id
  custom_network_interface_name = each.value.private_endpoint.custom_network_interface_name

  ip_configuration {
    name               = "ipconfig"
    private_ip_address = each.value.private_endpoint.ip_configuration.private_ip_address
    subresource_name   = each.value.private_endpoint.subresource_name
    member_name        = each.value.private_endpoint.member_name
  }

  private_service_connection {
    name                           = each.value.key_vault_name
    private_connection_resource_id = azurerm_key_vault.main[each.value.key_vault_name].id
    is_manual_connection           = false
    subresource_names = [
      each.value.private_endpoint.subresource_name
    ]
  }

  private_dns_zone_group {
    name = "${each.value.key_vault_name}-private-dns-zone-group"

    private_dns_zone_ids = each.value.private_endpoint.private_dns_zone_ids != null ? each.value.private_endpoint.private_dns_zone_ids : [for private_dns_zone_name in each.value.private_endpoint.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
  }

  depends_on = [
    azurerm_key_vault.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}
