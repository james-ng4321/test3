resource "azurerm_cdn_frontdoor_profile" "main" {
  for_each = {
    for cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : cdn_frontdoor_profile.name => cdn_frontdoor_profile
  }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  sku_name            = each.value.sku_name

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    iterator = identity
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids != null ? identity.value.identity_ids : [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id]
    }
  }
}
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  for_each = {
    for index, cdn_frontdoor_endpoint in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_endpoint in cdn_frontdoor_profile.cdn_frontdoor_endpoints : merge(
          cdn_frontdoor_endpoint,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]
    ])) : cdn_frontdoor_endpoint.name => cdn_frontdoor_endpoint
  }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[each.value.cdn_profile_name].id
  enabled                  = each.value.enabled
  tags                     = each.value.tags

  depends_on = [
    azurerm_cdn_frontdoor_profile.main
  ]
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  for_each = {
    for index, cdn_frontdoor_origin_group in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_origin_group in cdn_frontdoor_profile.cdn_frontdoor_origin_groups : merge(
          cdn_frontdoor_origin_group,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]
    ])) : cdn_frontdoor_origin_group.name => cdn_frontdoor_origin_group
  }
  name                                                      = each.value.name
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.main[each.value.cdn_profile_name].id
  session_affinity_enabled                                  = each.value.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "health_probe" {
    for_each = each.value.health_probe != null ? [each.value.health_probe] : []
    iterator = health_probe
    content {
      interval_in_seconds = health_probe.value.interval_in_seconds
      path                = health_probe.value.path
      protocol            = health_probe.value.protocol
      request_type        = health_probe.value.request_type
    }
  }

  dynamic "load_balancing" {
    for_each = each.value.load_balancing != null ? [each.value.load_balancing] : []
    iterator = load_balancing
    content {
      additional_latency_in_milliseconds = load_balancing.value.additional_latency_in_milliseconds
      sample_size                        = load_balancing.value.sample_size
      successful_samples_required        = load_balancing.value.successful_samples_required
    }
  }
  depends_on = [
    azurerm_cdn_frontdoor_profile.main
  ]
}

resource "azurerm_cdn_frontdoor_origin" "main" {
  for_each = {
    for index, cdn_frontdoor_origin in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_origin_group in coalesce(cdn_frontdoor_profile.cdn_frontdoor_origin_groups, []) : [
          for index, cdn_frontdoor_origin in cdn_frontdoor_origin_group.cdn_frontdoor_origins : merge(
            cdn_frontdoor_origin,
            {
              cdn_origin_group_name = cdn_frontdoor_origin_group.name
              cdn_profile_name      = cdn_frontdoor_profile.name
            }
          )
      ]]
    ])) : cdn_frontdoor_origin.name => cdn_frontdoor_origin
  }
  name                           = each.value.name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main[each.value.cdn_origin_group_name].id
  host_name                      = each.value.host_name
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  enabled                        = each.value.enabled
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority
  weight                         = each.value.weight

  dynamic "private_link" {
    for_each = each.value.private_link != null ? [each.value.private_link] : []
    iterator = private_link
    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_profile.main,
    azurerm_cdn_frontdoor_origin_group.main
  ]
}


resource "azurerm_cdn_frontdoor_route" "main" {
  for_each = {
    for index, cdn_frontdoor_route in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_route in cdn_frontdoor_profile.cdn_frontdoor_routes : merge(
          cdn_frontdoor_route,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]]
    )) : cdn_frontdoor_route.name => cdn_frontdoor_route
  }
  name                            = each.value.name
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.main[each.value.cdn_frontdoor_endpoint_name].id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.main[each.value.cdn_frontdoor_origin_group_name].id
  cdn_frontdoor_origin_ids        = [for cdn_frontdoor_origin_name in each.value.cdn_frontdoor_origin_names : azurerm_cdn_frontdoor_origin.main[cdn_frontdoor_origin_name].id]
  forwarding_protocol             = each.value.forwarding_protocol
  patterns_to_match               = each.value.patterns_to_match
  supported_protocols             = each.value.supported_protocols
  cdn_frontdoor_custom_domain_ids = each.value.cdn_frontdoor_custom_domain_ids != null ? each.value.cdn_frontdoor_custom_domain_ids : each.value.cdn_frontdoor_custom_domain_names != null ? [for cdn_frontdoor_custom_domain_name in each.value.cdn_frontdoor_custom_domain_names : azurerm_cdn_frontdoor_custom_domain.main[cdn_frontdoor_custom_domain_name].id] : null
  cdn_frontdoor_origin_path       = each.value.cdn_frontdoor_origin_path
  cdn_frontdoor_rule_set_ids      = each.value.cdn_frontdoor_rule_set_ids
  enabled                         = each.value.enabled
  https_redirect_enabled          = each.value.https_redirect_enabled
  link_to_default_domain          = each.value.link_to_default_domain

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    iterator = cache
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_profile.main,
    azurerm_cdn_frontdoor_origin_group.main,
    azurerm_cdn_frontdoor_custom_domain.main
  ]
}

resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  for_each = {
    for index, cdn_frontdoor_custom_domain in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_custom_domain in coalesce(cdn_frontdoor_profile.cdn_frontdoor_custom_domains, []) : merge(
          cdn_frontdoor_custom_domain,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]]
    )) : cdn_frontdoor_custom_domain.name => cdn_frontdoor_custom_domain
  }

  name                     = each.value.name
  host_name                = each.value.host_name
  dns_zone_id              = each.value.dns_zone_id
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[each.value.cdn_profile_name].id

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id != null ? each.value.tls.cdn_frontdoor_secret_id : each.value.tls.cdn_frontdoor_secret_name != null ? azurerm_cdn_frontdoor_secret.main[each.value.tls.cdn_frontdoor_secret_name].id : null
  }

  depends_on = [
    azurerm_cdn_frontdoor_profile.main
  ]
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "main" {
  for_each = {
    for index, cdn_frontdoor_custom_domain in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_custom_domain in coalesce(cdn_frontdoor_profile.cdn_frontdoor_custom_domains, []) : merge(
          cdn_frontdoor_custom_domain,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        ) if cdn_frontdoor_custom_domain.cdn_frontdoor_route_names != null
      ]]
    )) : cdn_frontdoor_custom_domain.name => cdn_frontdoor_custom_domain
  }
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.main[each.value.name].id
  cdn_frontdoor_route_ids        = [for cdn_frontdoor_route_name in each.value.cdn_frontdoor_route_names : azurerm_cdn_frontdoor_route.main[cdn_frontdoor_route_name].id]

  depends_on = [
    azurerm_cdn_frontdoor_profile.main,
    azurerm_cdn_frontdoor_custom_domain.main,
    azurerm_cdn_frontdoor_route.main
  ]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  for_each = {
    for index, cdn_frontdoor_firewall_policy in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for cdn_frontdoor_firewall_policy in coalesce(cdn_frontdoor_profile.cdn_frontdoor_firewall_policies, []) : cdn_frontdoor_firewall_policy
      ]
    ])) : cdn_frontdoor_firewall_policy.name => cdn_frontdoor_firewall_policy
  }

  name                                      = each.value.name
  resource_group_name                       = each.value.resource_group_name
  sku_name                                  = each.value.sku_name
  enabled                                   = each.value.enabled
  js_challenge_cookie_expiration_in_minutes = each.value.js_challenge_cookie_expiration_in_minutes
  mode                                      = each.value.mode
  request_body_check_enabled                = each.value.request_body_check_enabled
  redirect_url                              = each.value.redirect_url

  dynamic "custom_rule" {
    for_each = each.value.custom_rules != null ? each.value.custom_rules : []
    iterator = custom_rule
    content {
      name     = custom_rule.value.name
      action   = custom_rule.value.action
      enabled  = custom_rule.value.enabled
      priority = custom_rule.value.priority
      type     = custom_rule.value.type

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions != null ? custom_rule.value.match_conditions : []
        iterator = match_condition
        content {
          match_variable     = match_condition.value.match_variable
          match_values       = match_condition.value.match_values
          operator           = match_condition.value.operator
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
    }
  }
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body

  dynamic "log_scrubbing" {
    for_each = each.value.log_scrubbing != null ? [each.value.log_scrubbing] : []
    iterator = log_scrubbing
    content {
      enabled = log_scrubbing.value.enabled

      dynamic "scrubbing_rule" {
        for_each = log_scrubbing.value.scrubbing_rules != null ? log_scrubbing.value.scrubbing_rules : []
        iterator = scrubbing_rule
        content {
          match_variable = scrubbing_rule.value.match_variable
          selector       = scrubbing_rule.value.selector
          operator       = scrubbing_rule.value.operator
          enabled        = scrubbing_rule.value.enabled
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = each.value.managed_rules != null ? each.value.managed_rules : []
    iterator = managed_rule
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusions != null ? managed_rule.value.exclusions : []
        iterator = exclusion
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }

      dynamic "override" {
        for_each = managed_rule.value.overrides != null ? managed_rule.value.overrides : []
        iterator = override
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "exclusion" {
            for_each = override.value.exclusions != null ? override.value.exclusions : []
            iterator = exclusion
            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }

          dynamic "rule" {
            for_each = override.value.rules != null ? override.value.rules : []
            iterator = rule
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = rule.value.enabled

              dynamic "exclusion" {
                for_each = rule.value.exclusions != null ? rule.value.exclusions : []
                iterator = exclusion
                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }


    }
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  for_each = {
    for index, cdn_frontdoor_security_policy in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for cdn_frontdoor_security_policy in coalesce(cdn_frontdoor_profile.cdn_frontdoor_security_policies, []) : merge(
          cdn_frontdoor_security_policy,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]
    ])) : cdn_frontdoor_security_policy.name => cdn_frontdoor_security_policy
  }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[each.value.cdn_profile_name].id
  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = each.value.security_policies.firewall.cdn_frontdoor_firewall_policy_id != null ? each.value.security_policies.firewall.cdn_frontdoor_firewall_policy_id : azurerm_cdn_frontdoor_firewall_policy.main[each.value.security_policies.firewall.cdn_frontdoor_firewall_policy_name].id
      association {
        dynamic "domain" {
          for_each = each.value.security_policies.firewall.association.domains
          iterator = domain
          content {
            cdn_frontdoor_domain_id = domain.value.cdn_frontdoor_domain_id != null ? domain.value.cdn_frontdoor_domain_id : domain.value.cdn_frontdoor_domain_type == "Endpoint" ? azurerm_cdn_frontdoor_endpoint.main[domain.value.cdn_frontdoor_domain_name].id : azurerm_cdn_frontdoor_custom_domain.main[domain.value.cdn_frontdoor_domain_name].id
            # active                  = domain.value.active
          }
        }
        patterns_to_match = each.value.security_policies.firewall.association.patterns_to_match
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_secret" "main" {
  for_each = {
    for index, cdn_frontdoor_secret in coalesce(flatten([
      for index, cdn_frontdoor_profile in coalesce(var.cdn_frontdoor_profiles, []) : [
        for index, cdn_frontdoor_secret in coalesce(cdn_frontdoor_profile.cdn_frontdoor_secret, []) : merge(
          cdn_frontdoor_secret,
          {
            cdn_profile_name = cdn_frontdoor_profile.name
          }
        )
      ]
    ])) : cdn_frontdoor_secret.name => cdn_frontdoor_secret
  }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[each.value.cdn_profile_name].id
  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.secret.customer_certificate.key_vault_certificate_id
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_profile.main
  ]
}

