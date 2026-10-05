resource "azurerm_static_web_app" "main" {
  for_each = {
    for static_web_app_name, static_web_app in coalesce(var.static_web_apps, []) : static_web_app.name => static_web_app
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku_tier            = each.value.sku_tier
  sku_size            = each.value.sku_size

  tags = each.value.tags

  dynamic "basic_auth" {
    for_each = each.value.basic_auth != null ? [each.value.basic_auth] : []

    content {
      password     = each.value.basic_auth.password
      environments = each.value.basic_auth.environments
    }
  }

  configuration_file_changes_enabled = each.value.configuration_file_changes_enabled
  preview_environments_enabled       = each.value.preview_environments_enabled
  public_network_access_enabled      = each.value.public_network_access_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  app_settings      = each.value.app_settings
  repository_branch = each.value.repository_branch
  repository_url    = each.value.repository_url
  repository_token  = each.value.repository_token

  depends_on = [
    azurerm_resource_group.main
  ]
}
