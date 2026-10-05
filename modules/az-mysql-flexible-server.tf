resource "azurerm_mysql_flexible_server" "main" {
  for_each = {
    for mysql_server in coalesce(var.mysql_flexible_servers, []) : mysql_server.name => mysql_server
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  administrator_login    = var.mysql_flexible_servers_administrator_login
  administrator_password = var.mysql_flexible_servers_administrator_password

  backup_retention_days        = each.value.backup_retention_days
  geo_redundant_backup_enabled = each.value.geo_redundant_backup_enabled
  sku_name                     = each.value.sku_name
  version                      = each.value.version
  zone                         = each.value.zone

  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [each.value.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  dynamic "storage" {
    for_each = each.value.storage != null ? [each.value.storage] : []
    content {
      auto_grow_enabled = storage.value.auto_grow_enabled
      iops              = storage.value.iops
      size_gb           = storage.value.size_gb
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key != null ? [each.value.customer_managed_key] : []
    content {
      key_vault_key_id                     = customer_managed_key.value.key_vault_key_id
      primary_user_assigned_identity_id    = customer_managed_key.value.primary_user_assigned_identity_id
      geo_backup_key_vault_key_id          = customer_managed_key.value.geo_backup_key_vault_key_id
      geo_backup_user_assigned_identity_id = customer_managed_key.value.geo_backup_user_assigned_identity_id
    }
  }

  delegated_subnet_id   = each.value.delegated_subnet_id
  private_dns_zone_id   = each.value.private_dns_zone_id
  public_network_access = each.value.public_network_access

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      administrator_login,
      administrator_password,
      zone
    ]
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_subnet.main
  ]
}

# MySQL Flexible Server Configuration
resource "azurerm_mysql_flexible_server_configuration" "main" {
  for_each = {
    for config in coalesce(flatten([
      for mysql_server in coalesce(var.mysql_flexible_servers, []) : [
        for configuration in coalesce(mysql_server.configurations, []) : merge(configuration, {
          mysql_server_name = mysql_server.name
        })
      ]
    ]), []) : "${config.mysql_server_name}-${config.name}" => config
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[each.value.mysql_server_name].name
  value               = each.value.value

  depends_on = [
    azurerm_mysql_flexible_server.main
  ]
}

# MySQL Flexible Server Firewall Rule
resource "azurerm_mysql_flexible_server_firewall_rule" "main" {
  for_each = {
    for firewall_rule in coalesce(flatten([
      for mysql_server in coalesce(var.mysql_flexible_servers, []) : [
        for firewall_rule in coalesce(mysql_server.firewall_rules, []) : merge(firewall_rule, {
          mysql_server_name = mysql_server.name
        })
      ]
    ]), []) : "${firewall_rule.mysql_server_name}-${firewall_rule.name}" => firewall_rule
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[each.value.mysql_server_name].name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address

  depends_on = [
    azurerm_mysql_flexible_server.main
  ]
}

# MySQL Flexible Server Database
resource "azurerm_mysql_flexible_database" "main" {
  for_each = {
    for database in coalesce(flatten([
      for mysql_server in coalesce(var.mysql_flexible_servers, []) : [
        for database in coalesce(mysql_server.databases, []) : merge(database, {
          mysql_server_name = mysql_server.name
        })
      ]
    ]), []) : "${database.mysql_server_name}-${database.name}" => database
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[each.value.mysql_server_name].name
  charset             = each.value.charset
  collation           = each.value.collation

  depends_on = [
    azurerm_mysql_flexible_server.main
  ]
}

# Private Endpoint for MySQL Flexible Server
resource "azurerm_private_endpoint" "mysql_flexible_server" {
  for_each = {
    for private_endpoint in coalesce(flatten([
      for mysql_server in coalesce(var.mysql_flexible_servers, []) : [
        for private_endpoint in coalesce(mysql_server.private_endpoints, []) : merge(private_endpoint, {
          mysql_server_name   = mysql_server.name
          resource_group_name = mysql_server.resource_group_name
          location            = mysql_server.location
        })
      ]
    ]), []) : "${private_endpoint.mysql_server_name}-${private_endpoint.name}" => private_endpoint
  }

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = azurerm_subnet.main[each.value.subnet_name].id
  custom_network_interface_name = each.value.custom_network_interface_name

  private_service_connection {
    name                           = "${each.value.name}-connection"
    private_connection_resource_id = azurerm_mysql_flexible_server.main[each.value.mysql_server_name].id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration != null ? [each.value.ip_configuration] : []
    content {
      name               = "ipconfig1"
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = "mysqlServer"
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
    azurerm_mysql_flexible_server.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}
