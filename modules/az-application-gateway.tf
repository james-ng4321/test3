resource "azurerm_public_ip" "application_gateway_frontend" {
  for_each = {
    for index, frontend_ip_configuration in coalesce(flatten([
      for index, application_gateway in coalesce(var.application_gateways, []) : [
        for index, frontend_ip_configuration in application_gateway.frontend_ip_configurations : merge(
          frontend_ip_configuration,
          {
            resource_group_name = application_gateway.resource_group_name
            location            = application_gateway.location
          }
        ) if frontend_ip_configuration.public_ip != null
      ]
    ])) : frontend_ip_configuration.public_ip.name => frontend_ip_configuration
  }

  name                = each.value.public_ip.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.public_ip.allocation_method
  sku                 = each.value.public_ip.sku
  zones               = each.value.public_ip.zones

  depends_on = [
    azurerm_resource_group.main
  ]
}

resource "azurerm_application_gateway" "main" {
  for_each = {
    for index, application_gateway in coalesce(var.application_gateways, []) : application_gateway.name => application_gateway
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  zones               = each.value.zones
  http2_enabled       = each.value.enable_http2
  firewall_policy_id  = each.value.firewall_policy_id != null ? each.value.firewall_policy_id : each.value.firewall_policy_name != null ? azurerm_web_application_firewall_policy.main[each.value.firewall_policy_name].id : null

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.sku.capacity
  }

  dynamic "autoscale_configuration" {
    for_each = each.value.autoscale_configuration != null ? [each.value.autoscale_configuration] : []

    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  dynamic "gateway_ip_configuration" {
    for_each = {
      for index, gateway_ip_configuration in each.value.gateway_ip_configurations : gateway_ip_configuration.name => gateway_ip_configuration
    }
    iterator = gateway_ip_configuration

    content {
      name      = gateway_ip_configuration.value.name
      subnet_id = gateway_ip_configuration.value.subnet_id != null ? gateway_ip_configuration.value.subnet_id : azurerm_subnet.main[gateway_ip_configuration.value.subnet_name].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = {
      for index, frontend_ip_configuration in each.value.frontend_ip_configurations : frontend_ip_configuration.name => frontend_ip_configuration
    }
    iterator = frontend_ip_configuration

    content {
      name                            = frontend_ip_configuration.value.name
      subnet_id                       = frontend_ip_configuration.value.subnet_id != null ? frontend_ip_configuration.value.subnet_id : frontend_ip_configuration.value.subnet_name != null ? azurerm_subnet.main[frontend_ip_configuration.value.subnet_name].id : null
      private_ip_address              = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation   = frontend_ip_configuration.value.private_ip_address_allocation
      public_ip_address_id            = frontend_ip_configuration.value.public_ip_address_id != null ? frontend_ip_configuration.value.public_ip_address_id : frontend_ip_configuration.value.public_ip != null ? azurerm_public_ip.application_gateway_frontend[frontend_ip_configuration.value.public_ip.name].id : null
      private_link_configuration_name = frontend_ip_configuration.value.private_link_configuration_name
    }
  }

  dynamic "frontend_port" {
    for_each = {
      for index, frontend_port in each.value.frontend_ports : frontend_port.name => frontend_port
    }
    iterator = frontend_port

    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  dynamic "backend_address_pool" {
    for_each = {
      for index, backend_address_pool in each.value.backend_address_pools : backend_address_pool.name => backend_address_pool
    }
    iterator = backend_address_pool

    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = {
      for index, backend_http_settings in each.value.all_backend_http_settings : backend_http_settings.name => backend_http_settings
    }
    iterator = backend_http_settings

    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      path                                = backend_http_settings.value.path
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      probe_name                          = backend_http_settings.value.probe_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      host_name                           = backend_http_settings.value.host_name
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "authentication_certificate" {
        for_each = {
          for index, authentication_certificate in coalesce(backend_http_settings.value.authentication_certificates, []) : authentication_certificate.name => authentication_certificate
        }
        iterator = authentication_certificate

        content {
          name = authentication_certificate.value.name
        }
      }

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? [backend_http_settings.value.connection_draining] : []
        iterator = connection_draining

        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = {
      for index, http_listener in each.value.http_listeners : http_listener.name => http_listener
    }
    iterator = http_listener

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      firewall_policy_id             = http_listener.value.firewall_policy_id
      ssl_profile_name               = http_listener.value.ssl_profile_name

      dynamic "custom_error_configuration" {
        for_each = {
          for index, error_configuration in coalesce(http_listener.value.custom_error_configurations, []) : error_configuration.name => error_configuration
        }
        iterator = error_configuration

        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = {
      for index, request_routing_rule in each.value.request_routing_rules : request_routing_rule.name => request_routing_rule
    }
    iterator = request_routing_rule

    content {
      name                        = request_routing_rule.value.name
      priority                    = request_routing_rule.value.priority
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "probe" {
    for_each = {
      for index, probe in coalesce(each.value.probes, []) : probe.name => probe
    }

    content {
      name                = probe.value.name
      interval            = probe.value.interval
      protocol            = probe.value.protocol
      path                = probe.value.path
      timeout             = probe.value.timeout
      unhealthy_threshold = probe.value.unhealthy_threshold

      host                                      = probe.value.host
      port                                      = probe.value.port
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      minimum_servers                           = probe.value.minimum_servers

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []

        content {
          status_code = match.value.status_code
          body        = match.value.body
        }
      }
    }
  }

  dynamic "ssl_certificate" {
    for_each = {
      for index, ssl_certificate in coalesce(each.value.ssl_certificates, []) : ssl_certificate.name => ssl_certificate
    }
    iterator = ssl_certificate

    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.certificate_path != null ? filebase64(ssl_certificate.value.certificate_path) : null
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "redirect_configuration" {
    for_each = {
      for index, rc in coalesce(each.value.redirect_configurations, []) : rc.name => rc
    }
    iterator = rc

    content {
      name                 = rc.value.name
      redirect_type        = rc.value.redirect_type
      target_listener_name = rc.value.target_listener_name
      include_path         = rc.value.include_path
      include_query_string = rc.value.include_query_string
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_virtual_network.main,
    azurerm_public_ip.application_gateway_frontend,
    azurerm_user_assigned_identity.main,
    azurerm_web_application_firewall_policy.main
  ]
}

resource "azurerm_role_assignment" "identity_agw_network_contributor" {
  for_each = {
    for item in coalesce(flatten([
      for agw in coalesce(var.application_gateways, []) : [
        for identity_name in coalesce(agw.allow_identity_network_contributor, []) : {
          agw_name      = agw.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${item.agw_name}-${item.identity_name}" => item
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_application_gateway.main[each.value.agw_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_application_gateway.main,
    azurerm_user_assigned_identity.main
  ]
}
