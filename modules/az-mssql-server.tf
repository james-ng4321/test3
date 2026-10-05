resource "azurerm_mssql_server" "main" {
  for_each = {
    for mssql_server_name, mssql_server in coalesce(var.mssql_servers, []) : mssql_server.name => mssql_server
  }
  name                                    = each.value.name
  resource_group_name                     = each.value.resource_group_name
  location                                = each.value.location
  version                                 = each.value.version
  administrator_login                     = var.mssql_servers_administrator_login
  administrator_login_password            = var.mssql_servers_administrator_login_password
  administrator_login_password_wo         = each.value.administrator_login_password_wo
  administrator_login_password_wo_version = each.value.administrator_login_password_wo_version

  dynamic "azuread_administrator" {
    for_each = each.value.azuread_administrator != null ? [each.value.azuread_administrator] : []

    content {
      login_username              = each.value.azuread_administrator.login_username
      object_id                   = each.value.azuread_administrator.object_id
      tenant_id                   = each.value.azuread_administrator.tenant_id
      azuread_authentication_only = each.value.azuread_administrator.azuread_authentication_only
    }
  }

  connection_policy                            = each.value.connection_policy
  express_vulnerability_assessment_enabled     = each.value.express_vulnerability_assessment_enabled
  transparent_data_encryption_key_vault_key_id = each.value.transparent_data_encryption_key_vault_key_id
  minimum_tls_version                          = each.value.minimum_tls_version
  public_network_access_enabled                = each.value.public_network_access_enabled
  outbound_network_restriction_enabled         = each.value.outbound_network_restriction_enabled
  primary_user_assigned_identity_id            = each.value.primary_user_assigned_identity_id != null ? each.value.primary_user_assigned_identity_id : azurerm_user_assigned_identity.main[each.value.primary_user_assigned_identity_name].id

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      administrator_login,
      administrator_login_password
    ]
  }

  depends_on = [
    azurerm_resource_group.main,
  ]
}

provider "azurerm" {
  features {}
  alias           = "azurerm_mssql_server_monitor_storage"
  subscription_id = var.mssql_server_monitor_storage_subscription_id
  tenant_id       = var.tenant_id
}

data "azurerm_storage_account" "azurerm_mssql_server_monitor_storage" {
  for_each = {
    for mssql_server_name, mssql_server in coalesce(var.mssql_servers, []) : mssql_server.name => mssql_server if mssql_server.mssql_server_extended_auditing_policy != null
  }
  provider            = azurerm.azurerm_mssql_server_monitor_storage
  name                = each.value.mssql_server_extended_auditing_policy.storage_account_name
  resource_group_name = each.value.mssql_server_extended_auditing_policy.storage_resource_group_name
}

resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  # for_each = {
  #   for index, mssql_server_extended_auditing_policy in coalesce(flatten([
  #     for index, mssql_server in coalesce(var.mssql_servers, []) : [
  #       for index, mssql_server_extended_auditing_policy in coalesce(mssql_server.mssql_server_extended_auditing_policy, []) : merge(mssql_server_extended_auditing_policy, {
  #         mssql_server_name = mssql_server.name
  #       })
  #     ]
  #   ]), []) : mssql_server_extended_auditing_policy.mssql_server_name => mssql_server_extended_auditing_policy
  # }
  for_each = {
    for mssql_server in coalesce(var.mssql_servers, []) : mssql_server.name => mssql_server.mssql_server_extended_auditing_policy if mssql_server.mssql_server_extended_auditing_policy != null
  }

  server_id                               = azurerm_mssql_server.main[each.key].id
  storage_endpoint                        = data.azurerm_storage_account.azurerm_mssql_server_monitor_storage[each.key].primary_blob_endpoint
  storage_account_access_key              = each.value.use_storage_account_access_key == true ? data.azurerm_storage_account.azurerm_mssql_server_monitor_storage[each.key].primary_access_key : null
  storage_account_access_key_is_secondary = each.value.storage_account_access_key_is_secondary
  retention_in_days                       = each.value.retention_in_days
  log_monitoring_enabled                  = each.value.log_monitoring_enabled
  audit_actions_and_groups                = each.value.audit_actions_and_groups
}

resource "azurerm_private_endpoint" "mssql_server" {
  for_each = { for index, private_endpoint in coalesce(flatten([
    for mssql_server_name, mssql_server in coalesce(var.mssql_servers, []) : [
      for private_endpoint_name, private_endpoint in coalesce(mssql_server.private_endpoints, []) : {
        mssql_server_name   = mssql_server.name
        resource_group_name = mssql_server.resource_group_name
        location            = mssql_server.location
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
    name                           = each.value.mssql_server_name
    private_connection_resource_id = azurerm_mssql_server.main[each.value.mssql_server_name].id
    is_manual_connection           = false
    subresource_names = [
      each.value.private_endpoint.subresource_name
    ]
  }

  private_dns_zone_group {
    name = "${each.value.mssql_server_name}-private-dns-zone-group"

    private_dns_zone_ids = each.value.private_endpoint.private_dns_zone_ids != null ? each.value.private_endpoint.private_dns_zone_ids : [for private_dns_zone_name in each.value.private_endpoint.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
  }

  depends_on = [
    azurerm_mssql_server.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}

resource "azurerm_mssql_database" "main" {
  for_each = {
    for index, mssql_database in coalesce(flatten([
      for mssql_server_name, mssql_server in coalesce(var.mssql_servers, []) : [
        for mssql_database_name, mssql_database in coalesce(mssql_server.mssql_databases, []) : {
          mssql_server_name   = mssql_server.name
          resource_group_name = mssql_server.resource_group_name
          location            = mssql_server.location
          mssql_database      = mssql_database
        }
      ]
  ]), []) : mssql_database.mssql_database.name => mssql_database }

  name                           = each.value.mssql_database.name
  auto_pause_delay_in_minutes    = each.value.mssql_database.auto_pause_delay_in_minutes
  create_mode                    = each.value.mssql_database.create_mode
  server_id                      = azurerm_mssql_server.main[each.value.mssql_server_name].id
  collation                      = each.value.mssql_database.collation
  enclave_type                   = each.value.mssql_database.enclave_type
  geo_backup_enabled             = each.value.mssql_database.geo_backup_enabled
  maintenance_configuration_name = each.value.mssql_database.maintenance_configuration_name
  sku_name                       = each.value.mssql_database.sku_name
  min_capacity                   = each.value.mssql_database.min_capacity
  max_size_gb                    = each.value.mssql_database.max_size_gb
  storage_account_type           = each.value.mssql_database.storage_account_type
  zone_redundant                 = each.value.mssql_database.zone_redundant


  dynamic "identity" {
    for_each = each.value.mssql_database.identity != null ? [each.value.mssql_database.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  dynamic "short_term_retention_policy" {
    for_each = each.value.mssql_database.short_term_retention_policy != null ? [each.value.mssql_database.short_term_retention_policy] : []
    iterator = short_term_retention_policy
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = short_term_retention_policy.value.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = each.value.mssql_database.long_term_retention_policy != null ? [each.value.mssql_database.long_term_retention_policy] : []
    iterator = long_term_retention_policy
    content {
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      week_of_year      = long_term_retention_policy.value.week_of_year
    }
  }

  tags = each.value.mssql_database.tags

  depends_on = [
    azurerm_mssql_server.main
  ]
}
