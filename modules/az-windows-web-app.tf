resource "azurerm_windows_web_app" "main" {
  for_each = {
    for index, windows_web_app in coalesce(var.windows_web_apps, []) : windows_web_app.name => windows_web_app
  }

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  service_plan_id     = each.value.service_plan_id != null ? each.value.service_plan_id : azurerm_service_plan.main[each.value.service_plan_name].id

  site_config {
    always_on          = each.value.site_config.always_on
    api_definition_url = each.value.site_config.api_definition_url
    app_command_line   = each.value.site_config.app_command_line

    dynamic "application_stack" {
      for_each = each.value.site_config.application_stack != null ? [each.value.site_config.application_stack] : []
      iterator = application_stack
      content {
        current_stack                = application_stack.value.current_stack
        docker_image_name            = application_stack.value.docker_image_name
        docker_registry_url          = application_stack.value.docker_registry_url
        docker_registry_username     = application_stack.value.docker_registry_username
        docker_registry_password     = application_stack.value.docker_registry_password
        dotnet_version               = application_stack.value.dotnet_version
        dotnet_core_version          = application_stack.value.dotnet_core_version
        tomcat_version               = application_stack.value.tomcat_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        java_version                 = application_stack.value.java_version
        node_version                 = application_stack.value.node_version
        php_version                  = application_stack.value.php_version
        python                       = application_stack.value.python
      }
    }

    dynamic "auto_heal_setting" {
      for_each = each.value.site_config.auto_heal_setting != null ? [each.value.site_config.auto_heal_setting] : []
      iterator = auto_heal_setting
      content {
        action {
          action_type = auto_heal_setting.value.action.action_type

          dynamic "custom_action" {
            for_each = auto_heal_setting.value.custom_action != null ? [auto_heal_setting.value.custom_action] : []
            iterator = custom_action
            content {
              executable = custom_action.value.executable
              parameters = custom_action.value.parameters
            }
          }
          minimum_process_execution_time = auto_heal_setting.value.action.minimum_process_execution_time
        }

        trigger {
          private_memory_kb = auto_heal_setting.value.trigger.private_memory_kb

          dynamic "requests" {
            for_each = auto_heal_setting.value.trigger.requests != null ? [auto_heal_setting.value.trigger.requests] : []
            iterator = requests
            content {
              count    = requests.value.count
              interval = requests.value.interval
            }
          }

          dynamic "slow_request" {
            for_each = auto_heal_setting.value.trigger.slow_request != null ? [auto_heal_setting.value.trigger.slow_request] : []
            iterator = slow_request
            content {
              count      = slow_request.value.count
              interval   = slow_request.value.interval
              time_taken = slow_request.value.time_taken
            }
          }

          dynamic "slow_request_with_path" {
            for_each = auto_heal_setting.value.trigger.slow_request_with_path != null ? auto_heal_setting.value.trigger.slow_request_with_path : []
            iterator = slow_request_with_path
            content {
              count      = slow_request_with_path.value.count
              interval   = slow_request_with_path.value.interval
              time_taken = slow_request_with_path.value.time_taken
              path       = slow_request_with_path.value.path
            }
          }

          dynamic "status_code" {
            for_each = auto_heal_setting.value.trigger.status_code != null ? auto_heal_setting.value.trigger.status_code : []
            iterator = status_code
            content {
              count             = status_code.value.count
              interval          = status_code.value.interval
              status_code_range = status_code.value.status_code_range
              path              = status_code.value.path
              sub_status        = status_code.value.sub_status
              win32_status_code = status_code.value.win32_status_code
            }
          }
        }
      }
    }

    container_registry_managed_identity_client_id = each.value.site_config.container_registry_managed_identity_client_id
    container_registry_use_managed_identity       = each.value.site_config.container_registry_use_managed_identity

    dynamic "cors" {
      for_each = each.value.site_config.cors != null ? [each.value.site_config.cors] : []
      iterator = cors
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = cors.value.support_credentials
      }
    }

    default_documents                 = each.value.site_config.default_documents
    ftps_state                        = each.value.site_config.ftps_state
    health_check_path                 = each.value.site_config.health_check_path
    health_check_eviction_time_in_min = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                     = each.value.site_config.http2_enabled

    dynamic "ip_restriction" {
      for_each = each.value.site_config.ip_restrictions != null ? each.value.site_config.ip_restrictions : []
      iterator = ip_restriction
      content {
        action = ip_restriction.value.action

        dynamic "headers" {
          for_each = ip_restriction.value.headers != null ? [ip_restriction.value.headers] : []
          iterator = headers
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }
        ip_address                = ip_restriction.value.ip_address
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = (ip_restriction.value.virtual_network_subnet_id != null ? ip_restriction.value.virtual_network_subnet_id : (ip_restriction.value.virtual_network_subnet_name != null ? azurerm_subnet.main[ip_restriction.value.virtual_network_subnet_name].id : null))
        description               = ip_restriction.value.description
      }
    }

    ip_restriction_default_action = each.value.site_config.ip_restriction_default_action
    load_balancing_mode           = each.value.site_config.load_balancing_mode
    local_mysql_enabled           = each.value.site_config.local_mysql_enabled
    managed_pipeline_mode         = each.value.site_config.managed_pipeline_mode
    minimum_tls_version           = each.value.site_config.minimum_tls_version
    remote_debugging_enabled      = each.value.site_config.remote_debugging_enabled
    remote_debugging_version      = each.value.site_config.remote_debugging_version

    dynamic "scm_ip_restriction" {
      for_each = each.value.site_config.scm_ip_restrictions != null ? each.value.site_config.scm_ip_restrictions : []
      iterator = scm_ip_restriction
      content {
        action = scm_ip_restriction.value.action

        dynamic "headers" {
          for_each = scm_ip_restriction.value.headers != null ? [scm_ip_restriction.value.headers] : []
          iterator = headers
          content {
            x_azure_fdid      = headers.value.x_azure_fdid
            x_fd_health_probe = headers.value.x_fd_health_probe
            x_forwarded_for   = headers.value.x_forwarded_for
            x_forwarded_host  = headers.value.x_forwarded_host
          }
        }

        ip_address                = scm_ip_restriction.value.ip_address
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = (scm_ip_restriction.value.virtual_network_subnet_id != null ? scm_ip_restriction.value.virtual_network_subnet_id : (scm_ip_restriction.value.virtual_network_subnet_name != null ? azurerm_subnet.main[scm_ip_restriction.value.virtual_network_subnet_name].id : null))
        description               = scm_ip_restriction.value.description
      }
    }
    scm_ip_restriction_default_action = each.value.site_config.scm_ip_restriction_default_action
    scm_minimum_tls_version           = each.value.site_config.scm_minimum_tls_version
    scm_use_main_ip_restriction       = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker                 = each.value.site_config.use_32_bit_worker

    dynamic "handler_mapping" {
      for_each = each.value.site_config.handler_mappings != null ? [each.value.site_config.handler_mappings] : []
      iterator = handler_mapping
      content {
        extension             = handler_mappinp.value.extension
        script_processor_path = handler_mapping.value.script_processor_path
        arguments             = handler_mapping.value.arguments
      }
    }

    dynamic "virtual_application" {
      for_each = each.value.site_config.virtual_applications != null ? [each.value.site_config.virtual_applications] : []
      iterator = virtual_application
      content {
        physical_path = virtual_application.value.physical_path
        preload       = virtual_application.value.preload
        virtual_path  = virtual_application.value.virtual_path

        dynamic "virtual_directory" {
          for_each = virtual_application.value.virtual_directories != null ? [virtual_application.value.virtual_directories] : []
          iterator = virtual_directory
          content {
            physical_path = virtual_directory.value.physical_path
            virtual_path  = virtual_directory.value.virtual_path
          }
        }
      }
    }
    vnet_route_all_enabled = each.value.site_config.vnet_route_all_enabled
    websockets_enabled     = each.value.site_config.websockets_enabled
    worker_count           = each.value.site_config.worker_count
  }

  app_settings = each.value.app_settings

  dynamic "auth_settings" {
    for_each = each.value.auth_settings != null ? [each.value.auth_settings] : []
    iterator = auth_settings
    content {
      enabled = auth_settings.value.enabled

      dynamic "active_directory" {
        for_each = auth_settings.value.active_directory != null ? [auth_settings.value.active_directory] : []
        iterator = active_directory
        content {
          client_id                  = active_directory.value.client_id
          allowed_audiences          = active_directory.value.allowed_audiences
          client_secret              = active_directory.value.client_secret
          client_secret_setting_name = active_directory.value.client_secret_setting_name
        }
      }

      additional_login_parameters    = auth_settings.value.additional_login_parameters
      allowed_external_redirect_urls = auth_settings.value.allowed_external_redirect_urls
      default_provider               = auth_settings.value.default_provider
    }
  }

  dynamic "auth_settings_v2" {
    for_each = each.value.auth_settings_v2 != null ? [each.value.auth_settings_v2] : []
    iterator = auth_settings_v2
    content {
      auth_enabled                          = auth_settings_v2.value.auth_enabled
      runtime_version                       = auth_settings_v2.value.runtime_version
      config_file_path                      = auth_settings_v2.value.config_file_path
      require_authentication                = auth_settings_v2.value.require_authentication
      unauthenticated_action                = auth_settings_v2.value.unauthenticated_action
      default_provider                      = auth_settings_v2.value.default_provider
      excluded_paths                        = auth_settings_v2.value.excluded_paths
      require_https                         = auth_settings_v2.value.require_https
      http_route_api_prefix                 = auth_settings_v2.value.http_route_api_prefix
      forward_proxy_convention              = auth_settings_v2.value.forward_proxy_convention
      forward_proxy_custom_host_header_name = auth_settings_v2.value.forward_proxy_custom_host_header_name

      dynamic "apple_v2" {
        for_each = auth_settings_v2.value.apple_v2 != null ? [auth_settings_v2.apple_v2] : []
        iterator = apple_v2
        content {
          client_id                  = apple_v2.value.client_id
          client_secret_setting_name = apple_v2.value.client_secret_setting_name
          login_scopes               = apple_v2.value.login_scopes
        }
      }

      dynamic "active_directory_v2" {
        for_each = auth_settings_v2.value.active_directory_v2 != null ? [auth_settings_v2.active_directory_v2] : []
        iterator = active_directory_v2
        content {
          client_id                            = active_directory_v2.value.client_id
          tenant_auth_endpoint                 = active_directory_v2.value.tenant_auth_endpoint
          client_secret_setting_name           = active_directory_v2.value.client_secret_setting_name
          client_secret_certificate_thumbprint = active_directory_v2.value.client_secret_certificate_thumbprint
          jwt_allowed_groups                   = active_directory_v2.value.jwt_allowed_groups
          jwt_allowed_client_applications      = active_directory_v2.value.jwt_allowed_client_applications
          www_authentication_disabled          = active_directory_v2.value.www_authentication_disabled
          allowed_groups                       = active_directory_v2.value.allowed_groups
          allowed_identities                   = active_directory_v2.value.allowed_identities
          allowed_applications                 = active_directory_v2.value.allowed_applications
          login_parameters                     = active_directory_v2.value.login_parameters
          allowed_audiences                    = active_directory_v2.value.allowed_audiences
        }
      }

      dynamic "azure_static_web_app_v2" {
        for_each = auth_settings_v2.value.azure_static_web_app_v2 != null ? [auth_settings_v2.azure_static_web_app_v2] : []
        iterator = azure_static_web_app_v2
        content {
          client_id = azure_static_web_app_v2.value.client_id
        }
      }

      dynamic "custom_oidc_v2" {
        for_each = auth_settings_v2.value.custom_oidc_v2 != null ? [auth_settings_v2.custom_oidc_v2] : []
        iterator = custom_oidc_v2
        content {
          name                          = custom_oidc_v2.value.name
          client_id                     = custom_oidc_v2.value.client_id
          openid_configuration_endpoint = custom_oidc_v2.value.openid_configuration_endpoint
          name_claim_type               = custom_oidc_v2.value.name_claim_type
          scopes                        = custom_oidc_v2.value.scopes
          client_credential_method      = custom_oidc_v2.value.client_credential_method
          client_secret_setting_name    = custom_oidc_v2.value.client_secret_setting_name
          authorisation_endpoint        = custom_oidc_v2.value.authorisation_endpoint
          token_endpoint                = custom_oidc_v2.value.token_endpoint
          issuer_endpoint               = custom_oidc_v2.value.issuer_endpoint
          certification_uri             = custom_oidc_v2.value.certification_uri
        }
      }

      dynamic "facebook_v2" {
        for_each = auth_settings_v2.value.facebook_v2 != null ? [auth_settings_v2.facebook_v2] : []
        iterator = facebook_v2
        content {
          app_id                  = facebook_v2.value.app_id
          app_secret_setting_name = facebook_v2.value.app_secret_setting_name
          graph_api_version       = facebook_v2.value.graph_api_version
          login_scopes            = facebook_v2.value.login_scopes
        }
      }

      dynamic "github_v2" {
        for_each = auth_settings_v2.value.github_v2 != null ? [auth_settings_v2.github_v2] : []
        iterator = github_v2
        content {
          client_id                  = github_v2.value.client_id
          client_secret_setting_name = github_v2.value.client_secret_setting_name
          login_scopes               = github_v2.value.login_scopes
        }
      }

      dynamic "google_v2" {
        for_each = auth_settings_v2.value.google_v2 != null ? [auth_settings_v2.google_v2] : []
        iterator = google_v2
        content {
          client_id                  = google_v2.value.client_id
          client_secret_setting_name = google_v2.value.client_secret_setting_name
          allowed_audiences          = google_v2.value.allowed_audiences
          login_scopes               = google_v2.value.login_scopes
        }
      }

      dynamic "microsoft_v2" {
        for_each = auth_settings_v2.value.microsoft_v2 != null ? [auth_settings_v2.microsoft_v2] : []
        iterator = microsoft_v2
        content {
          client_id                  = microsoft_v2.value.client_id
          client_secret_setting_name = microsoft_v2.value.client_secret_setting_name
          allowed_audiences          = microsoft_v2.value.allowed_audiences
          login_scopes               = microsoft_v2.value.login_scopes
        }
      }

      dynamic "twitter_v2" {
        for_each = auth_settings_v2.value.twitter_v2 != null ? [auth_settings_v2.twitter_v2] : []
        iterator = twitter_v2
        content {
          consumer_key                 = twitter_v2.value.consumer_key
          consumer_secret_setting_name = twitter_v2.value.consumer_secret_setting_name
        }
      }

      login {
        logout_endpoint                   = auth_settings_v2.value.login.logout_endpoint
        token_store_enabled               = auth_settings_v2.value.login.token_store_enabled
        token_refresh_extension_time      = auth_settings_v2.value.login.token_refresh_extension_time
        token_store_path                  = auth_settings_v2.value.login.token_store_path
        token_store_sas_setting_name      = auth_settings_v2.value.login.token_store_sas_setting_name
        preserve_url_fragments_for_logins = auth_settings_v2.value.login.preserve_url_fragments_for_logins
        allowed_external_redirect_urls    = auth_settings_v2.value.login.allowed_external_redirect_urls
        cookie_expiration_convention      = auth_settings_v2.value.login.cookie_expiration_convention
        cookie_expiration_time            = auth_settings_v2.value.login.cookie_expiration_time
        validate_nonce                    = auth_settings_v2.value.login.validate_nonce
        nonce_expiration_time             = auth_settings_v2.value.login.nonce_expiration_time
      }
    }
  }

  dynamic "backup" {
    for_each = each.value.backup != null ? [each.value.backup] : []
    iterator = backup
    content {
      name = backup.value.name
      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = backup.value.schedule.keep_at_least_one_backup
        retention_period_days    = backup.value.schedule.retention_period_days
        start_time               = backup.value.schedule.start_time
      }
      storage_account_url = backup.value.storage_account_url
      enabled             = backup.value.enabled
    }
  }


  client_affinity_enabled            = each.value.client_affinity_enabled
  client_certificate_enabled         = each.value.client_certificate_enabled
  client_certificate_mode            = each.value.client_certificate_mode
  client_certificate_exclusion_paths = each.value.client_certificate_exclusion_paths

  dynamic "connection_string" {
    for_each = each.value.connection_strings != null ? [each.value.connection_strings] : []
    iterator = connection_string
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
  enabled                                  = each.value.enabled
  ftp_publish_basic_authentication_enabled = each.value.ftp_publish_basic_authentication_enabled
  https_only                               = each.value.https_only
  public_network_access_enabled            = each.value.public_network_access_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    iterator = identity
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  key_vault_reference_identity_id = each.value.key_vault_reference_identity_id

  dynamic "logs" {
    for_each = each.value.logs != null ? [each.value.logs] : []
    iterator = logs
    content {
      dynamic "application_logs" {
        for_each = logs.value.application_logs != null ? [logs.value.application_logs] : []
        iterator = application_logs
        content {
          dynamic "azure_blob_storage" {
            for_each = application_logs.value.azure_blob_storage != null ? [application_logs.value.azure_blob_storage] : []
            iterator = azure_blob_storage
            content {
              level             = azure_blob_storage.value.level
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url           = azure_blob_storage.value.sas_url
            }
          }
          file_system_level = application_logs.value.file_system_level
        }
      }
      detailed_error_messages = logs.value.detailed_error_messages
      failed_request_tracing  = logs.value.failed_request_tracing

      dynamic "http_logs" {
        for_each = logs.value.http_logs != null ? [logs.value.http_logs] : []
        iterator = http_logs
        content {
          dynamic "azure_blob_storage" {
            for_each = http_logs.value.azure_blob_storage != null ? [http_logs.value.azure_blob_storage] : []
            iterator = azure_blob_storage
            content {
              retention_in_days = azure_blob_storage.value.retention_in_days
              sas_url           = azure_blob_storage.value.sas_url
            }
          }
          dynamic "file_system" {
            for_each = http_logs.value.file_system != null ? [http_logs.value.file_system] : []
            iterator = file_system
            content {
              retention_in_days = file_system.value.retention_in_days
              retention_in_mb   = file_system.value.retention_in_mb
            }
          }
        }
      }
    }
  }

  dynamic "sticky_settings" {
    for_each = each.value.sticky_settings != null ? [each.value.sticky_settings] : []
    iterator = sticky_settings
    content {
      app_setting_names       = sticky_settings.value.app_setting_names
      connection_string_names = sticky_settings.value.connection_string_names
    }
  }

  dynamic "storage_account" {
    for_each = each.value.storage_accounts != null ? [each.value.storage_accounts] : []
    iterator = storage_account
    content {
      access_key   = storage_account.value.access_key
      account_name = storage_account.value.account_name
      name         = storage_account.value.name
      share_name   = storage_account.value.share_name
      type         = storage_account.value.type
      mount_path   = storage_account.value.mount_path
    }
  }
  tags = each.value.tags
  #   virtual_network_backup_restore_enabled         = each.value.virtual_network_backup_restore_enabled
  virtual_network_subnet_id                      = each.value.virtual_network_subnet_id != null ? each.value.virtual_network_subnet_id : azurerm_subnet.main[each.value.virtual_network_subnet_name].id
  webdeploy_publish_basic_authentication_enabled = each.value.webdeploy_publish_basic_authentication_enabled
  zip_deploy_file                                = each.value.zip_deploy_file

  depends_on = [
    azurerm_resource_group.main,
    azurerm_subnet.main,
    azurerm_service_plan.main
  ]
}

resource "azurerm_private_endpoint" "windows_web_app" {
  for_each = { for index, private_endpoint in coalesce(flatten([
    for index, windows_web_app in coalesce(var.windows_web_apps, []) : [
      for private_endpoint_name, private_endpoint in coalesce(windows_web_app.private_endpoints, []) : {
        windows_web_app_name = windows_web_app.name
        resource_group_name  = windows_web_app.resource_group_name
        location             = windows_web_app.location
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
    name                           = each.value.windows_web_app_name
    private_connection_resource_id = azurerm_windows_web_app.main[each.value.windows_web_app_name].id
    is_manual_connection           = false
    subresource_names = [
      each.value.private_endpoint.subresource_name
    ]
  }

  private_dns_zone_group {
    name = "${each.value.windows_web_app_name}-private-dns-zone-group"

    private_dns_zone_ids = each.value.private_endpoint.private_dns_zone_ids != null ? each.value.private_endpoint.private_dns_zone_ids : [for private_dns_zone_name in each.value.private_endpoint.private_dns_zone_names : azurerm_private_dns_zone.main[private_dns_zone_name].id]
  }

  depends_on = [
    azurerm_windows_web_app.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main
  ]
}
