resource "azurerm_data_factory" "main" {
  for_each = {
    for data_factory_name, data_factory in coalesce(var.data_factories, []) : data_factory.name => data_factory
  }
  name                             = each.value.name
  location                         = each.value.location
  resource_group_name              = each.value.resource_group_name
  public_network_enabled           = each.value.public_network_enabled
  managed_virtual_network_enabled  = each.value.managed_virtual_network_enabled
  customer_managed_key_id          = each.value.customer_managed_key_id
  customer_managed_key_identity_id = each.value.customer_managed_key_identity_id
  purview_id                       = each.value.purview_id
  tags                             = each.value.tags

  dynamic "github_configuration" {
    for_each = each.value.github_configuration != null ? [each.value.github_configuration] : []

    content {
      account_name       = each.value.github_configuration.account_name
      branch_name        = each.value.github_configuration.branch_name
      git_url            = each.value.github_configuration.git_url
      repository_name    = each.value.github_configuration.repository_name
      root_folder        = each.value.github_configuration.root_folder
      publishing_enabled = each.value.github_configuration.publishing_enabled
    }
  }

  dynamic "global_parameter" {
    for_each = each.value.global_parameter != null ? [each.value.global_parameter] : []

    content {
      name  = each.value.global_parameter.name
      type  = each.value.global_parameter.type
      value = each.value.global_parameter.value
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  dynamic "vsts_configuration" {
    for_each = each.value.vsts_configuration != null ? [each.value.vsts_configuration] : []

    content {
      account_name       = each.value.vsts_configuration.account_name
      branch_name        = each.value.vsts_configuration.branch_name
      project_name       = each.value.vsts_configuration.project_name
      repository_name    = each.value.vsts_configuration.repository_name
      root_folder        = each.value.vsts_configuration.root_folder
      tenant_id          = each.value.vsts_configuration.tenant_id
      publishing_enabled = each.value.vsts_configuration.publishing_enabled
    }
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_user_assigned_identity.main
  ]
}

resource "azurerm_private_endpoint" "data_factory" {
  for_each = { for index, private_endpoint in coalesce(flatten([
    for data_factory_name, data_factory in coalesce(var.data_factories, []) : [
      for private_endpoint_name, private_endpoint in coalesce(data_factory.private_endpoints, []) : {
        data_factory_name   = data_factory.name
        resource_group_name = data_factory.resource_group_name
        location            = data_factory.location
        private_endpoint    = private_endpoint
      }
    ]
  ]), []) : private_endpoint.private_endpoint.name => private_endpoint }

  name                = each.value.private_endpoint.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  subnet_id                     = each.value.private_endpoint.subnet_id == null ? azurerm_subnet.main[each.value.private_endpoint.subnet_name].id : each.value.private_endpoint.subnet_id
  custom_network_interface_name = each.value.private_endpoint.custom_network_interface_name

  ip_configuration {
    name               = "ipconfig"
    private_ip_address = each.value.private_endpoint.ip_configuration.private_ip_address
    subresource_name   = each.value.private_endpoint.subresource_name
    member_name        = each.value.private_endpoint.member_name
  }

  private_service_connection {
    name                           = each.value.data_factory_name
    private_connection_resource_id = azurerm_data_factory.main[each.value.data_factory_name].id
    is_manual_connection           = false
    subresource_names = [
      each.value.private_endpoint.subresource_name
    ]
  }

  private_dns_zone_group {
    name = "${each.value.data_factory_name}-private-dns-zone-group"

    private_dns_zone_ids = each.value.private_endpoint.private_dns_zone_ids != null ? each.value.private_endpoint.private_dns_zone_ids : [for private_dns_zone_name in each.value.private_endpoint.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
  }

  depends_on = [
    azurerm_data_factory.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}
