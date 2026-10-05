resource "azurerm_storage_account" "main" {
  for_each = {
    for storage_account_name, storage_account in coalesce(var.storage_accounts, []) : storage_account.name => storage_account
  }
  name                             = each.value.name
  location                         = each.value.location
  resource_group_name              = each.value.resource_group_name
  account_kind                     = each.value.account_kind
  account_tier                     = each.value.account_tier
  account_replication_type         = each.value.account_replication_type
  cross_tenant_replication_enabled = each.value.cross_tenant_replication_enabled

  edge_zone   = each.value.edge_zone
  access_tier = each.value.access_tier

  # Security
  min_tls_version    = each.value.min_tls_version
  allowed_copy_scope = each.value.allowed_copy_scope
  dynamic "sas_policy" {
    for_each = each.value.sas_policy == null ? [] : [each.value.sas_policy]
    iterator = sas_policy
    content {
      expiration_period = sas_policy.value.expiration_period
      expiration_action = sas_policy.value.expiration_action
    }
  }

  # Encryption
  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key == null ? [] : [each.value.customer_managed_key]
    iterator = customer_managed_key
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled

  # Network
  dynamic "custom_domain" {
    for_each = each.value.custom_domain == null ? [] : [each.value.custom_domain]
    iterator = custom_domain
    content {
      name          = custom_domain.value.name
      use_subdomain = custom_domain.value.use_subdomain
    }
  }

  dynamic "network_rules" {
    for_each = each.value.network_rules == null ? [] : [each.value.network_rules]
    iterator = network_rules
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids

      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access == null ? [] : network_rules.value.private_link_access
        iterator = private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  sftp_enabled = each.value.sftp_enabled

  dynamic "routing" {
    for_each = each.value.routing == null ? [] : [each.value.routing]
    iterator = routing
    content {
      publish_internet_endpoints  = routing.value.publish_internet_endpoints
      publish_microsoft_endpoints = routing.value.publish_microsoft_endpoints
      choice                      = routing.value.choice
    }
  }

  # File
  dynamic "share_properties" {
    for_each = each.value.share_properties == null ? [] : [each.value.share_properties]
    iterator = share_properties
    content {
      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rule == null ? [] : [share_properties.value.cors_rule]
        iterator = cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }


      dynamic "smb" {
        for_each = share_properties.value.smb == null ? [] : [share_properties.value.smb]
        iterator = smb
        content {
          versions                        = smb.value.version
          authentication_types            = smb.value.authentication_types
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          channel_encryption_type         = smb.value.channel_encryption_type
          multichannel_enabled            = smb.value.multichannel_enabled
        }
      }
    }
  }

  dynamic "azure_files_authentication" {
    for_each = each.value.azure_files_authentication == null ? [] : [each.value.azure_files_authentication]
    iterator = azure_files_authentication
    content {
      directory_type = azure_files_authentication.value.directory_type

      dynamic "active_directory" {
        for_each = azure_files_authentication.value.active_directory == null ? [] : [azure_files_authentication.value.active_directory]
        iterator = active_directory
        content {
          domain_name         = active_directory.value.domain_name
          domain_guid         = active_directory.value.domain_guid
          domain_sid          = active_directory.value.domain_sid
          storage_sid         = active_directory.value.storage_sid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
        }
      }
    }
  }

  large_file_share_enabled = each.value.large_file_share_enabled
  # local_user_enabled       = each.value.local_user_enabled

  # Blob

  dynamic "blob_properties" {
    for_each = each.value.blob_properties == null ? [] : [each.value.blob_properties]
    iterator = blob_properties
    content {
      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule == null ? [] : [blob_properties.value.cors_rule]
        iterator = cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy == null ? [] : [blob_properties.value.delete_retention_policy]
        iterator = delete_retention_policy
        content {
          days = delete_retention_policy.value.days
        }
      }

      dynamic "restore_policy" {
        for_each = blob_properties.value.restore_policy == null ? [] : [blob_properties.value.restore_policy]
        iterator = restore_policy
        content {
          days = restore_policy.value.days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy == null ? [] : [blob_properties.value.container_delete_retention_policy]
        iterator = container_delete_retention_policy
        content {
          days = container_delete_retention_policy.value.days
        }
      }
      versioning_enabled            = blob_properties.value.versioning_enabled
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled
    }
  }

  dynamic "immutability_policy" {
    for_each = each.value.immutability_policy == null ? [] : [each.value.immutability_policy]
    iterator = immutability_policy
    content {
      allow_protected_append_writes = immutability_policy.value.allow_protected_append_writes
      state                         = immutability_policy.value.state
      period_since_creation_in_days = immutability_policy.value.period_since_creation_in_days
    }
  }

  dynamic "queue_properties" {
    for_each = each.value.queue_properties == null ? [] : [each.value.queue_properties]
    iterator = queue_properties
    content {
      dynamic "cors_rule" {
        for_each = queue_properties.value.cors_rule == null ? [] : [queue_properties.value.cors_rule]
        iterator = cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = queue_properties.value.logging == null ? [] : [queue_properties.value.logging]
        iterator = logging
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          version               = logging.value.version
          write                 = logging.value.write
          retention_policy_days = logging.value.retention_policy_days
        }
      }

      dynamic "minute_metrics" {
        for_each = queue_properties.value.minute_metrics == null ? [] : [queue_properties.value.minute_metrics]
        iterator = minute_metrics
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = minute_metrics.value.include_apis
          retention_policy_days = minute_metrics.value.retention_policy_days
        }
      }

      dynamic "hour_metrics" {
        for_each = queue_properties.value.hour_metrics == null ? [] : [queue_properties.value.hour_metrics]
        iterator = hour_metrics
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = hour_metrics.value.include_apis
          retention_policy_days = hour_metrics.value.retention_policy_days
        }
      }
    }
  }

  queue_encryption_key_type = each.value.queue_encryption_key_type

  # Table
  # enable_https_traffic_only       = each.value.enable_https_traffic_only
  https_traffic_only_enabled = each.value.https_traffic_only_enabled

  allow_nested_items_to_be_public = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled       = each.value.shared_access_key_enabled
  public_network_access_enabled   = each.value.public_network_access_enabled
  is_hns_enabled                  = each.value.is_hns_enabled
  nfsv3_enabled                   = each.value.nfsv3_enabled
  table_encryption_key_type       = each.value.table_encryption_key_type

  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]
    iterator = identity
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "static_website" {
    for_each = each.value.static_website == null ? [] : [each.value.static_website]
    iterator = static_website
    content {
      index_document     = static_website.value.index_document
      error_404_document = static_website.value.error_404_document
    }
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

resource "azurerm_storage_container" "main" {
  for_each = { for index, container in coalesce(flatten([
    for storage_account_name, storage_account in coalesce(var.storage_accounts, []) : [
      for container_name, container in coalesce(storage_account.containers, []) : {
        storage_account_name = storage_account.name
        container            = container
      }
    ]
  ]), []) : "${container.storage_account_name}.${container.container.name}" => container }

  storage_account_id = azurerm_storage_account.main[each.value.storage_account_name].id
  # storage_account_name = azurerm_storage_account.main.name

  name                  = each.value.container.name
  container_access_type = each.value.container.container_access_type
  metadata              = each.value.container.metadata

  depends_on = [
    azurerm_storage_account.main
  ]
}


resource "azurerm_private_endpoint" "storage_account" {
  for_each = { for index, private_endpoint in coalesce(flatten([
    for storage_account_name, storage_account in coalesce(var.storage_accounts, []) : [
      for private_endpoint_name, private_endpoint in coalesce(storage_account.private_endpoints, []) : {
        storage_account_name = storage_account.name
        resource_group_name  = storage_account.resource_group_name
        location             = storage_account.location
        private_endpoint     = private_endpoint
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
    name                           = each.value.storage_account_name
    private_connection_resource_id = azurerm_storage_account.main[each.value.storage_account_name].id
    is_manual_connection           = false
    subresource_names = [
      each.value.private_endpoint.subresource_name
    ]
  }

  private_dns_zone_group {
    name = "${each.value.storage_account_name}-private-dns-zone-group"

    private_dns_zone_ids = each.value.private_endpoint.private_dns_zone_ids != null ? each.value.private_endpoint.private_dns_zone_ids : [for private_dns_zone_name in each.value.private_endpoint.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
  }

  depends_on = [
    azurerm_storage_account.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  for_each = {
    for index, monitor_diagnostic_setting in coalesce(flatten([
      for index, storage_account in coalesce(var.storage_accounts, []) : [
        for index, monitor_diagnostic_setting in coalesce(storage_account.monitor_diagnostic_settings, []) : merge(
          monitor_diagnostic_setting,
          {
            target_resource_name = storage_account.name
          }
        )
      ]
  ]), []) : monitor_diagnostic_setting.name => monitor_diagnostic_setting }

  name               = each.value.name
  target_resource_id = each.value.target_resource_id != null ? each.value.target_resource_id : each.value.sub_resource_name != null ? "${azurerm_storage_account.main[each.value.target_resource_name].id}/${each.value.sub_resource_name}/default/" : azurerm_storage_account.main[each.value.target_resource_name].id

  eventhub_name                  = each.value.eventhub_name
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id

  log_analytics_workspace_id = each.value.log_analytics_workspace_id != null ? each.value.log_analytics_workspace_id : (each.value.log_analytics_workspace_name != null ? azurerm_log_analytics_workspace.main[each.value.log_analytics_workspace_name].id : null)

  storage_account_id = each.value.storage_account_id != null ? each.value.storage_account_id : (each.value.storage_account_name != null ? azurerm_storage_account.main[each.value.storage_account_name].id : null)

  partner_solution_id            = each.value.partner_solution_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_metric" {
    for_each = each.value.metric != null ? each.value.metric : []
    iterator = enabled_metric

    content {
      category = enabled_metric.value.category
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.enabled_log != null ? each.value.enabled_log : []
    iterator = enabled_log
    content {
      category = enabled_log.value.category
    }
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_storage_account.main
  ]
}
