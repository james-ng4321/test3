# Global variable
variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

# Resource Group
variable "resource_groups" {
  type = list(
    object({
      name       = string
      location   = string
      managed_by = optional(string)
      tags       = optional(map(string))
    })
  )
}

# Virtual Network
variable "virtual_networks" {
  type = list(
    object({
      name                = string
      location            = string
      resource_group_name = string
      address_space       = list(string)
      dns_servers         = optional(list(string))
      tags                = optional(map(string))
      subnets = list(
        object({
          name              = string
          address_prefix    = string
          service_endpoints = optional(list(string))

          # private_endpoint_network_policies_enabled = optional(bool)
          private_endpoint_network_policies = optional(string)

          delegations = optional(list(object({
            name = string
            service_delegation = object({
              name    = string
              actions = optional(list(string))
            })
          })))

          network_security_group = optional(object({
            name = string

            rules = optional(list(object({
              name                                       = string
              priority                                   = number
              direction                                  = string
              access                                     = string
              protocol                                   = string
              description                                = optional(string)
              source_address_prefix                      = optional(string)
              source_address_prefixes                    = optional(list(string))
              source_port_range                          = optional(string)
              source_port_ranges                         = optional(list(string))
              source_application_security_group_ids      = optional(list(string))
              destination_address_prefix                 = optional(string)
              destination_address_prefixes               = optional(list(string))
              destination_port_range                     = optional(string)
              destination_port_ranges                    = optional(list(string))
              destination_application_security_group_ids = optional(list(string))
            })))

            monitor_diagnostic_setting = optional(object({
              name                         = string
              target_resource_id           = optional(string)
              log_analytics_workspace_name = optional(string)
              log_analytics_workspace_id   = optional(string)
              enabled_log = optional(list(object({
                category       = optional(string)
                category_group = optional(string)
              })))
            }))
          }))

          route_table = optional(object({
            name = string
            # disable_bgp_route_propagation = optional(bool)
            bgp_route_propagation_enabled = optional(bool)

            routes = optional(list(object({
              name                   = string
              address_prefix         = string
              next_hop_type          = string
              next_hop_in_ip_address = optional(string)
            })))
          }))
        })
      )
    })
  )
  default = null
}

variable "storage_accounts" {
  type = list(object({
    name                             = string
    location                         = string
    resource_group_name              = string
    account_kind                     = optional(string)
    account_tier                     = string
    account_replication_type         = string
    cross_tenant_replication_enabled = optional(bool)

    edge_zone   = optional(string)
    access_tier = optional(string)

    tags = optional(list(string))

    # Security
    min_tls_version    = optional(string)
    allowed_copy_scope = optional(string)
    sas_policy = optional(object({
      expiration_period = string
      expiration_action = string
    }))

    # Encryption
    customer_managed_key = optional(object({
      key_vault_key_id          = string
      user_assigned_identity_id = string
    }))

    infrastructure_encryption_enabled = optional(bool)

    # Network
    custom_domain = optional(object({
      name          = string
      use_subdomain = optional(bool)
    }))

    network_rules = optional(object({
      default_action             = string
      bypass                     = optional(list(string))
      ip_rules                   = optional(list(string))
      virtual_network_subnet_ids = optional(list(string))
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = string
      })))
    }))

    sftp_enabled = optional(bool)

    routing = optional(object({
      publish_internet_endpoints  = optional(bool)
      publish_microsoft_endpoints = optional(bool)
      choice                      = optional(string)
    }))

    # File
    share_properties = optional(object({
      cors_rule = optional(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      }))
      restore_policy = optional(object({
        days = optional(number)
      }))
      smb = optional(object({
        versions                        = optional(set(string))
        authentication_types            = optional(set(string))
        kerberos_ticket_encryption_type = optional(set(string))
        channel_encryption_type         = optional(set(string))
        multichannel_enabled            = optional(bool)
      }))
    }))

    azure_files_authentication = optional(object({
      directory_type = string
      active_directory = optional(object({
        domain_name         = string
        domain_guid         = string
        domain_sid          = optional(string)
        storage_sid         = optional(string)
        forest_name         = optional(string)
        netbios_domain_name = optional(string)
      }))
    }))

    large_file_share_enabled = optional(bool)
    local_user_enabled       = optional(bool)

    # Blob
    blob_properties = optional(object({
      cors_rule = optional(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      }))
      delete_retention_policy = optional(object({
        days = optional(number)
      }))
      restore_policy = optional(object({
        days = optional(number)
      }))
      container_delete_retention_policy = optional(object({
        days = optional(number)
      }))
      versioning_enabled            = optional(bool)
      change_feed_enabled           = optional(bool)
      change_feed_retention_in_days = optional(number)
      default_service_version       = optional(string)
      last_access_time_enabled      = optional(bool)
    }))

    immutability_policy = optional(object({
      allow_protected_append_writes = bool
      state                         = string
      period_since_creation_in_days = number
    }))

    # Queue
    queue_properties = optional(object({
      cors_rule = optional(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      }))
      logging = optional(object({
        delete                = bool
        read                  = bool
        version               = string
        write                 = bool
        retention_policy_days = number
      }))
      minute_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = bool
        retention_policy_days = bool
      }))
      hour_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = bool
        retention_policy_days = bool
      }))
    }))

    queue_encryption_key_type = optional(string)

    # Table

    # enable_https_traffic_only       = optional(bool)
    https_traffic_only_enabled = optional(bool)

    allow_nested_items_to_be_public = optional(bool)
    shared_access_key_enabled       = optional(bool)
    public_network_access_enabled   = optional(bool)
    is_hns_enabled                  = optional(bool)
    nfsv3_enabled                   = optional(bool)
    table_encryption_key_type       = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    # Static Web App
    static_website = optional(object({
      index_document     = optional(string)
      error_404_document = optional(string)
    }))

    # Containers
    containers = optional(list(object({
      name                  = string
      container_access_type = optional(string)
      metadata              = optional(map(string))
    })))

    # Private endpoints
    private_endpoints = optional(list(object({
      name                          = string
      custom_network_interface_name = optional(string)

      subresource_name = string
      member_name      = optional(string)

      ip_configuration = object({
        private_ip_address = string
      })

      # Subnet
      subnet_name = optional(string)
      subnet_id   = optional(string)

      private_dns_zone_names = optional(list(string))
      private_dns_zone_ids   = optional(list(string))
    })))

    # Diagnostic Settings
    monitor_diagnostic_settings = optional(list(object({
      name               = string
      sub_resource_name  = optional(string)
      target_resource_id = optional(string)

      eventhub_name                  = optional(string)
      eventhub_authorization_rule_id = optional(string)

      log_analytics_workspace_name = optional(string)
      log_analytics_workspace_id   = optional(string)

      storage_account_name = optional(string)
      storage_account_id   = optional(string)

      partner_solution_id            = optional(string)
      log_analytics_destination_type = optional(string)

      enabled_log = optional(list(object({
        category       = optional(string)
        category_group = optional(string)
      })))

      metric = optional(list(object({
        category = string
        enabled  = optional(bool)
      })))
    })))
  }))
  default = null
}

variable "private_dns_zones" {
  type = list(
    object({
      name                = string
      resource_group_name = string

      # virtual_networks_to_link = optional(list(object({
      #   name = string

      #   ## Option 1: virtual network resource id
      #   virtual_network_id = optional(string)

      #   ## Option 2: query id by virtual network name in same subscription
      #   resource_group_name  = optional(string)
      #   virtual_network_name = optional(string)

      #   registration_enabled = optional(bool)

      #   tags = optional(map(string))
      # })))

      soa_record = optional(object({
        email        = string
        expire_time  = optional(number)
        minimum_ttl  = optional(number)
        refresh_time = optional(number)
        retry_time   = optional(number)
        ttl          = optional(number)
        tags         = optional(map(string))
      }))

      a_records = optional(list(object({
        name    = string
        ttl     = number
        records = list(string)
        tags    = optional(map(string))
      })))

      aaaa_records = optional(list(object({
        name    = string
        ttl     = number
        records = list(string)
        tags    = optional(map(string))
      })))

      cname_records = optional(list(object({
        name   = string
        ttl    = number
        record = string
        tags   = optional(map(string))
      })))

      mx_records = optional(list(object({
        name = string
        ttl  = number
        records = list(object({
          preference = number
          exchange   = string
        }))
        tags = optional(map(string))
      })))

      ptr_records = optional(list(object({
        name    = string
        ttl     = number
        records = list(string)
        tags    = optional(map(string))
      })))

      srv_records = optional(list(object({
        name = string
        ttl  = number
        records = list(object({
          priority = number
          weight   = number
          port     = number
          target   = string
        }))
        tags = optional(map(string))
      })))

      txt_records = optional(list(object({
        name = string
        ttl  = number
        records = list(object({
          value = string
        }))
        tags = optional(map(string))
      })))

      virtual_network_links = list(object({
        name                 = string
        virtual_network_name = optional(string)
        virtual_network_id   = optional(string)
        registration_enabled = optional(bool)
        tags                 = optional(map(any))
      }))

      tags = optional(map(string))
    })
  )
  default = null
}

# Virtual Machine
variable "windows_virtual_machines" {
  type = list(
    object({
      name                       = string
      resource_group_name        = string
      location                   = string
      size                       = string
      zone                       = optional(number)
      computer_name              = string
      admin_username             = optional(string)
      admin_password             = optional(string)
      virtual_network_name       = string
      enable_automatic_updates   = optional(bool)
      patch_mode                 = optional(string)
      encryption_at_host_enabled = optional(bool)

      source_image_id                                        = optional(string)
      allow_extension_operations                             = optional(bool)
      availability_set_id                                    = optional(string)
      bypass_platform_safety_checks_on_user_schedule_enabled = optional(bool)
      capacity_reservation_group_id                          = optional(string)
      custom_data                                            = optional(string) // Base64
      dedicated_host_id                                      = optional(string)
      dedicated_host_group_id                                = optional(string)
      edge_zone                                              = optional(string)
      eviction_policy                                        = optional(string)
      extensions_time_budget                                 = optional(string)
      hotpatching_enabled                                    = optional(bool)
      license_type                                           = optional(string)
      max_bid_price                                          = optional(number)
      patch_assessment_mode                                  = optional(string)
      platform_fault_domain                                  = optional(number)
      priority                                               = optional(string)
      provision_vm_agent                                     = optional(bool)
      proximity_placement_group_id                           = optional(string)
      reboot_setting                                         = optional(string)
      secure_boot_enabled                                    = optional(bool)
      timezone                                               = optional(string)
      user_data                                              = optional(string) // Base64
      virtual_machine_scale_set_id                           = optional(string)
      vtpm_enabled                                           = optional(bool)

      additional_unattend_contents = optional(list(object({
        content = string // XML
        setting = string
      })))

      gallery_applications = optional(list(object({
        version_id             = string
        configuration_blob_uri = optional(string)
        order                  = optional(number)
        tag                    = optional(string)
      })))

      plan = optional(object({
        name      = string
        product   = string
        publisher = string
      }))

      secrets = optional(list(object({
        certificates = list(object({
          store = string
          url   = string
        }))
        key_vault_id = string
      })))

      termination_notification = optional(object({
        enabled = bool
        timeout = optional(number)
      }))

      winrm_listeners = optional(list(object({
        protocol        = string
        certificate_url = optional(string)
      })))

      network_interfaces = list(object({
        name                = string
        location            = string
        resource_group_name = string

        ip_configurations = list(object({
          name                                               = string
          gateway_load_balancer_frontend_ip_configuration_id = optional(string)
          subnet_name                                        = optional(string)
          private_ip_address_version                         = optional(string)
          private_ip_address_allocation                      = string
          public_ip_name                                     = optional(string)
          primary                                            = optional(bool)
          private_ip_address                                 = optional(string)
        }))
      }))

      os_disk = object({
        name                 = string
        caching              = string
        storage_account_type = string
        disk_size_gb         = optional(number)

        disk_encryption_set = optional(object({
          name                = string
          resource_group_name = string
          location            = string

          key_vault_name   = string
          key_vault_key_id = string

          auto_key_rotation_enabled = optional(string)
          encryption_type           = optional(string)
          federated_client_id       = optional(string)

          identity = object({
            type         = string
            identity_ids = optional(list(string))
          })

          tags = optional(map(string))
        }))
      })

      source_image_reference = optional(object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      }))

      boot_diagnostics = optional(object({
        storage_account_uri = optional(string)
      }))

      identity = optional(object({
        type           = string
        identity_ids   = optional(list(string))
        identity_names = optional(list(string))
      }))

      additional_capabilities = optional(object({
        ultra_ssd_enabled = string
      }))

      tags = optional(map(string))

      backup_protected_vm = optional(object({
        resource_group_name = optional(string)
        recovery_vault_name = string
        source_vm_id        = optional(string)
        backup_policy_id    = optional(string)
        backup_policy_name  = optional(string)
        exclude_disk_luns   = optional(list(string))
        include_disk_luns   = optional(list(string))
        protection_state    = optional(string)
      }))

      virtual_machine_data_disk_attachment = optional(list(object({
        managed_disk_name = string
        managed_disk_id   = string
        lun               = string
        caching           = string
      })))
    })
  )
  default = null
}

variable "windows_virtual_machines_admin_username" {
  type    = string
  default = ""
}

variable "windows_virtual_machines_admin_password" {
  type    = string
  default = ""
}

variable "linux_virtual_machines" {
  type = list(
    object({
      name                            = string
      resource_group_name             = string
      location                        = string
      size                            = string
      zone                            = optional(number)
      computer_name                   = string
      admin_username                  = optional(string)
      admin_password                  = optional(string)
      disable_password_authentication = optional(bool, false)
      virtual_network_name            = string
      encryption_at_host_enabled      = optional(bool)

      source_image_id                                        = optional(string)
      allow_extension_operations                             = optional(bool)
      availability_set_id                                    = optional(string)
      bypass_platform_safety_checks_on_user_schedule_enabled = optional(bool)
      capacity_reservation_group_id                          = optional(string)
      custom_data                                            = optional(string) // Base64
      dedicated_host_id                                      = optional(string)
      dedicated_host_group_id                                = optional(string)
      edge_zone                                              = optional(string)
      eviction_policy                                        = optional(string)
      extensions_time_budget                                 = optional(string)
      license_type                                           = optional(string)
      max_bid_price                                          = optional(number)
      patch_assessment_mode                                  = optional(string)
      patch_mode                                             = optional(string)
      platform_fault_domain                                  = optional(number)
      priority                                               = optional(string)
      provision_vm_agent                                     = optional(bool)
      proximity_placement_group_id                           = optional(string)
      reboot_setting                                         = optional(string)
      secure_boot_enabled                                    = optional(bool)
      user_data                                              = optional(string) // Base64
      virtual_machine_scale_set_id                           = optional(string)
      vtpm_enabled                                           = optional(bool)

      admin_ssh_keys = optional(list(object({
        username   = string
        public_key = string
      })))

      gallery_applications = optional(list(object({
        version_id             = string
        configuration_blob_uri = optional(string)
        order                  = optional(number)
        tag                    = optional(string)
      })))

      plan = optional(object({
        name      = string
        product   = string
        publisher = string
      }))

      secrets = optional(list(object({
        certificates = list(object({
          url = string
        }))
        key_vault_id = string
      })))

      termination_notification = optional(object({
        enabled = bool
        timeout = optional(number)
      }))

      network_interfaces = list(object({
        name                = string
        location            = string
        resource_group_name = string

        ip_configurations = list(object({
          name                                               = string
          gateway_load_balancer_frontend_ip_configuration_id = optional(string)
          subnet_name                                        = optional(string)
          private_ip_address_version                         = optional(string)
          private_ip_address_allocation                      = string
          public_ip_name                                     = optional(string)
          primary                                            = optional(bool)
          private_ip_address                                 = optional(string)
        }))
      }))

      os_disk = object({
        name                 = string
        caching              = string
        storage_account_type = string
        disk_size_gb         = optional(number)

        disk_encryption_set = optional(object({
          name                = string
          resource_group_name = string
          location            = string

          key_vault_name   = string
          key_vault_key_id = string

          auto_key_rotation_enabled = optional(string)
          encryption_type           = optional(string)
          federated_client_id       = optional(string)

          identity = object({
            type         = string
            identity_ids = optional(list(string))
          })

          tags = optional(map(string))
        }))
      })

      source_image_reference = optional(object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      }))

      boot_diagnostics = optional(object({
        storage_account_uri = optional(string)
      }))

      identity = optional(object({
        type           = string
        identity_ids   = optional(list(string))
        identity_names = optional(list(string))
      }))

      additional_capabilities = optional(object({
        ultra_ssd_enabled = string
      }))

      tags = optional(map(string))

      backup_protected_vm = optional(object({
        resource_group_name = optional(string)
        recovery_vault_name = string
        source_vm_id        = optional(string)
        backup_policy_id    = optional(string)
        backup_policy_name  = optional(string)
        exclude_disk_luns   = optional(list(string))
        include_disk_luns   = optional(list(string))
        protection_state    = optional(string)
      }))

      data_disks = optional(list(object({
        name                 = string
        storage_account_type = string
        create_option        = string
        disk_size_gb         = number
        lun                  = number
        caching              = string
        tags                 = optional(map(string))
      })))
    })
  )
  default = null
}

variable "linux_virtual_machines_admin_username" {
  type = string
}

variable "linux_virtual_machines_admin_password" {
  type = string
}

variable "key_vaults" {
  type = list(
    object({
      name = string

      resource_group_name = optional(string)
      location            = optional(string)

      sku_name  = string
      tenant_id = optional(string)

      self_access_policy = optional(object({
        application_id          = optional(string)
        certificate_permissions = optional(list(string))
        key_permissions         = optional(list(string))
        secret_permissions      = optional(list(string))
        storage_permissions     = optional(list(string))
      }))

      access_policies = optional(list(object({
        tenant_id               = string
        object_id               = string
        application_id          = optional(string)
        certificate_permissions = optional(list(string))
        key_permissions         = optional(list(string))
        secret_permissions      = optional(list(string))
        storage_permissions     = optional(list(string))
      })))

      enabled_for_deployment          = optional(bool)
      enabled_for_disk_encryption     = optional(bool)
      enabled_for_template_deployment = optional(bool)
      enable_rbac_authorization       = optional(bool)
      purge_protection_enabled        = optional(bool)
      public_network_access_enabled   = optional(bool)
      soft_delete_retention_days      = optional(number)

      network_acls = optional(object({
        bypass                     = string
        default_action             = string
        ip_rules                   = optional(list(string))
        virtual_network_subnet_ids = optional(list(string))
      }))

      contacts = optional(list(object({
        email = string
        name  = string
        phone = string
      })))

      keys = optional(list(object({
        name            = string
        key_type        = string
        key_size        = optional(string)
        curve           = optional(string)
        key_opts        = list(string)
        not_before_date = optional(string)
        expiration_date = optional(string)
        tags            = optional(map(string))
        rotation_policy = optional(object({
          expire_after = optional(string)
          automatic = optional(object({
            time_after_creation = optional(string)
            time_before_expiry  = optional(string)
          }))
          notify_before_expiry = optional(string)
        }))
      })))

      secrets_user_identity_names    = optional(list(string))
      secrets_user_aks_kubelet_names = optional(list(string))

      # Secrets (names + metadata only; values are supplied via the
      # sensitive var.key_vault_secret_values map, keyed by secret name)
      secrets = optional(list(object({
        name            = string
        content_type    = optional(string)
        not_before_date = optional(string)
        expiration_date = optional(string)
        tags            = optional(map(string))
      })))

      # Private endpoints
      private_endpoints = optional(list(object({
        name                          = string
        custom_network_interface_name = optional(string)

        subresource_name = string
        member_name      = optional(string)

        ip_configuration = object({
          private_ip_address = string
        })

        # Subnet
        subnet_name = optional(string)
        subnet_id   = optional(string)

        private_dns_zone_names = optional(list(string))
        private_dns_zone_ids   = optional(list(string))
      })))
    })
  )
  default = null
}

variable "key_vault_secret_values" {
  description = "Sensitive map of Key Vault secret name => value. Populated via a Terraform Cloud sensitive variable; keep the actual values out of source control."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "application_gateways" {
  type = list(
    object({
      name                 = string
      resource_group_name  = optional(string)
      location             = optional(string)
      zones                = optional(list(string))
      enable_http2         = optional(bool)
      firewall_policy_id   = optional(string)
      firewall_policy_name = optional(string)

      sku = object({
        name     = string
        tier     = string
        capacity = optional(number)
      })

      autoscale_configuration = optional(object({
        min_capacity = number
        max_capacity = number
      }))

      # gateway_ip_configurations = list(map(string))
      gateway_ip_configurations = list(object({
        name        = string
        subnet_id   = optional(string)
        subnet_name = optional(string)
      }))

      # frontend_ip_configurations = list(map(string))
      frontend_ip_configurations = list(object({
        name                            = string
        subnet_name                     = optional(string)
        subnet_id                       = optional(string)
        private_ip_address              = optional(string)
        public_ip_address_id            = optional(string)
        private_ip_address_allocation   = optional(string)
        private_link_configuration_name = optional(string)

        # Extra
        public_ip = optional(object({
          name              = string
          allocation_method = string
          sku               = optional(string)
          sku_tier          = optional(string)
          zones             = optional(list(string))
        }))
      }))

      frontend_ports = list(object({
        name = string
        port = number
      }))

      # backend_address_pools     = list(map(string))
      backend_address_pools = list(object({
        name         = string
        fqdns        = optional(list(string))
        ip_addresses = optional(list(string))
      }))

      # all_backend_http_settings = list(map(string))
      all_backend_http_settings = list(object({
        name                                = string
        cookie_based_affinity               = string
        protocol                            = string
        affinity_cookie_name                = optional(string)
        path                                = optional(string)
        port                                = optional(string)
        probe_name                          = optional(string)
        request_timeout                     = optional(number)
        host_name                           = optional(string)
        pick_host_name_from_backend_address = optional(bool)

        authentication_certificates = optional(list(object({
          name = string
        })))
        trusted_root_certificate_names = optional(list(string))
        connection_draining = optional(object({
          enabled           = bool
          drain_timeout_sec = number
        }))
      }))

      http_listeners = list(object({
        name                           = string
        frontend_ip_configuration_name = string
        frontend_port_name             = string
        protocol                       = string

        host_name            = optional(string)
        host_names           = optional(list(string))
        require_sni          = optional(string)
        ssl_certificate_name = optional(string)
        firewall_policy_id   = optional(string)
        ssl_profile_name     = optional(string)

        custom_error_configurations = optional(list(object({
          status_code           = string
          custom_error_page_url = string
        })))
      }))

      request_routing_rules = list(object({
        name               = string
        rule_type          = string
        http_listener_name = string

        backend_address_pool_name   = optional(string)
        backend_http_settings_name  = optional(string)
        redirect_configuration_name = optional(string)
        rewrite_rule_set_name       = optional(string)
        url_path_map_name           = optional(string)
        priority                    = optional(number)
      }))

      redirect_configurations = optional(list(object({
        name                 = string
        redirect_type        = string
        target_listener_name = optional(string)
        include_path         = optional(bool)
        include_query_string = optional(bool)
      })))

      probes = optional(list(object({
        name                = string
        interval            = number
        protocol            = string
        path                = string
        timeout             = number
        unhealthy_threshold = number

        host                                      = optional(string)
        port                                      = optional(number)
        pick_host_name_from_backend_http_settings = optional(bool)
        minimum_servers                           = optional(number)

        match = optional(object({
          status_code = list(string)
          body        = optional(string)
        }))
      })))

      ssl_certificates = optional(list(object({
        name                = string
        certificate_path    = optional(string)
        password            = optional(string)
        key_vault_secret_id = optional(string)
      })))

      identity = optional(object(
        {
          identity_names = optional(list(string))
          type           = string
          identity_ids   = optional(list(string))
        }
      ))

      monitor_diagnostic_settings = optional(list(object({
        name                         = string
        target_resource_id           = optional(string)
        log_analytics_workspace_name = optional(string)
        log_analytics_workspace_id   = optional(string)
        enabled_log = optional(list(object({
          category       = optional(string)
          category_group = optional(string)
        })))
        metric = optional(list(object({
          category = string
          enabled  = optional(bool)
        })))
      })))

      allow_identity_network_contributor = optional(list(string))
    })
  )

  # default = {
  #   name = "apw"
  #   sku = {
  #     name     = "Standard_v2"
  #     tier     = "Standard_v2"
  #     capacity = 1
  #   }

  #   gateway_ip_configurations  = []
  #   frontend_ip_configurations = []
  #   frontend_ports             = []
  #   backend_address_pools      = []
  #   all_backend_http_settings  = []
  #   http_listeners             = []
  #   request_routing_rules      = []
  # }
  default = null
}

variable "web_application_firewall_policies" {
  type = list(
    object({
      name                = string
      resource_group_name = string
      location            = string

      policy_settings = object({
        enabled                          = optional(bool, true)
        mode                             = optional(string, "Prevention")
        request_body_check               = optional(bool, true)
        file_upload_limit_in_mb          = optional(number, 100)
        max_request_body_size_in_kb      = optional(number, 128)
        request_body_inspect_limit_in_kb = optional(number, 128)
        request_body_enforcement         = optional(bool, true)
      })

      managed_rules = optional(object({
        exclusions = optional(list(object({
          match_variable          = string
          selector                = string
          selector_match_operator = string
          excluded_rule_sets = optional(list(object({
            type    = optional(string)
            version = optional(string)
            rule_groups = optional(list(object({
              rule_group_name = string
              excluded_rules  = optional(list(string))
            })))
          })))
        })))

        managed_rule_sets = optional(list(object({
          type    = optional(string, "OWASP")
          version = optional(string, "3.2")
          rule_group_overrides = optional(list(object({
            rule_group_name = string
            rules = optional(list(object({
              id      = string
              enabled = optional(bool)
              action  = optional(string)
            })))
          })))
        })))
      }))

      custom_rules = optional(list(object({
        name      = string
        priority  = number
        rule_type = string
        action    = string
        match_conditions = optional(list(object({
          match_variables = optional(list(object({
            variable_name = string
            selector      = optional(string)
          })))
          operator           = string
          negation_condition = optional(bool)
          match_values       = optional(list(string))
          transforms         = optional(list(string))
        })))
      })))
    })
  )
  default = null
}

variable "user_assigned_identities" {
  type = list(
    object(
      {
        name                = string
        location            = string
        resource_group_name = string
        grant_reader_role   = optional(bool, false)
        tags                = optional(map(any))
      }
    )
  )
  default = null
}

variable "data_factories" {
  type = list(
    object({
      name                = string
      resource_group_name = string
      location            = string

      github_configuration = optional(object({
        account_name       = string
        branch_name        = string
        git_url            = optional(string)
        repository_name    = string
        root_folder        = string
        publishing_enabled = optional(bool)
      }))

      global_parameter = optional(list(object({
        name  = string
        type  = string
        value = string
      })))

      identity = optional(object(
        {
          identity_names = optional(list(string))
          type           = string
          identity_ids   = optional(list(string))
        }
      ))

      vsts_configuration = optional(object({
        account_name       = string
        branch_name        = string
        project_name       = string
        repository_name    = string
        root_folder        = string
        tenant_id          = string
        publishing_enabled = optional(bool)
      }))

      public_network_enabled           = optional(bool)
      managed_virtual_network_enabled  = optional(bool)
      customer_managed_key_id          = optional(string)
      customer_managed_key_identity_id = optional(string)
      purview_id                       = optional(string)
      tags                             = optional(map(any))

      # private endpoints
      private_endpoints = optional(list(object({
        name                          = string
        custom_network_interface_name = optional(string)

        subresource_name = string
        member_name      = optional(string)

        ip_configuration = object({
          private_ip_address = string
        })

        # Subnet
        subnet_name = optional(string)
        subnet_id   = optional(string)

        private_dns_zone_names = optional(list(string))
        private_dns_zone_ids   = optional(list(string))
      })))
    })
  )
  default = null
}

variable "mssql_server_monitor_storage_subscription_id" {
  type    = string
  default = null
}

variable "mssql_servers" {
  type = list(
    object({
      name                                    = string
      resource_group_name                     = string
      location                                = string
      version                                 = optional(string)
      administrator_login                     = optional(string)
      administrator_login_password            = optional(string)
      administrator_login_password_wo         = optional(string)
      administrator_login_password_wo_version = optional(string)

      azuread_administrator = optional(object({
        login_username              = string
        object_id                   = string
        tenant_id                   = optional(string)
        azuread_authentication_only = optional(bool)
      }))

      connection_policy                            = optional(string)
      express_vulnerability_assessment_enabled     = optional(bool)
      transparent_data_encryption_key_vault_key_id = optional(bool)
      minimum_tls_version                          = optional(string)
      public_network_access_enabled                = optional(bool)
      outbound_network_restriction_enabled         = optional(bool)
      primary_user_assigned_identity_id            = optional(string)
      primary_user_assigned_identity_name          = optional(string)

      identity = optional(object(
        {
          identity_names = optional(list(string))
          type           = string
          identity_ids   = optional(list(string))
        }
      ))

      mssql_server_extended_auditing_policy = optional(object({
        enabled                                 = bool
        storage_resource_group_name             = optional(string)
        storage_account_name                    = optional(string)
        storage_endpoint                        = optional(string)
        retention_in_days                       = optional(number)
        use_storage_account_access_key          = bool
        storage_account_access_key              = optional(string)
        storage_account_access_key_is_secondary = optional(bool)
        log_monitoring_enabled                  = optional(bool)
        audit_actions_and_groups                = optional(list(string))
      }))

      tags = optional(map(string))

      # private endpoints
      private_endpoints = optional(list(object({
        name                          = string
        custom_network_interface_name = optional(string)

        subresource_name = string
        member_name      = optional(string)

        ip_configuration = object({
          private_ip_address = string
        })

        # Subnet
        subnet_name = optional(string)
        subnet_id   = optional(string)

        private_dns_zone_names = optional(list(string))
        private_dns_zone_ids   = optional(list(string))
      })))

      mssql_databases = optional(list(object({
        name                        = string
        auto_pause_delay_in_minutes = optional(string)
        create_mode                 = optional(string)

        import = optional(object({
          storage_uri                  = string
          storage_key                  = string
          storage_key_type             = string
          administrator_login          = string
          administrator_login_password = string
          authentication_type          = string
          storage_account_id           = optional(string)
        }))

        long_term_retention_policy = optional(object({
          weekly_retention  = optional(string)
          monthly_retention = optional(string)
          yearly_retention  = optional(string)
          week_of_year      = optional(number)
        }))

        short_term_retention_policy = optional(object({
          retention_days           = number
          backup_interval_in_hours = optional(number)
        }))

        creation_source_database_id    = optional(string)
        collation                      = optional(string)
        enclave_type                   = optional(string)
        geo_backup_enabled             = optional(bool)
        maintenance_configuration_name = optional(string)
        sku_name                       = optional(string)
        min_capacity                   = optional(string)
        max_size_gb                    = optional(string)
        storage_account_type           = optional(string)
        zone_redundant                 = optional(bool)

        identity = optional(object(
          {
            identity_names = optional(list(string))
            type           = string
            identity_ids   = optional(list(string))
          }
        ))

        tags = optional(map(string))
      })))
    })
  )
  default = null
}

variable "mssql_servers_administrator_login" {
  type    = string
  default = ""
}

variable "mssql_servers_administrator_login_password" {
  type    = string
  default = ""
}

variable "static_web_apps" {
  type = list(
    object({
      name                = string
      location            = string
      resource_group_name = string
      sku_tier            = optional(string)
      sku_size            = optional(string)
      tags                = optional(map(string))

      basic_auth = optional(object({
        password     = string
        environments = string
      }))

      configuration_file_changes_enabled = optional(bool)
      preview_environments_enabled       = optional(bool)
      public_network_access_enabled      = optional(bool)

      identity = optional(object({
        type         = string
        identity_ids = optional(list(string))
      }))

      app_settings      = optional(map(string))
      repository_branch = optional(string)
      repository_url    = optional(string)
      repository_token  = optional(string)
    })
  )
  default = null
}

# Service Plan
variable "service_plans" {
  type = list(
    object({
      name                         = string
      location                     = string
      resource_group_name          = string
      os_type                      = string
      sku_name                     = string
      app_service_environment_id   = optional(string)
      maximum_elastic_worker_count = optional(number)
      # premium_plan_auto_scale_enabled = optional(bool)
      worker_count             = optional(number)
      per_site_scaling_enabled = optional(bool)
      zone_balancing_enabled   = optional(bool)
      tags                     = optional(map(any))
    })
  )
  default = null

  # validation {
  #   condition = length([
  #     for service_plan in var.service_plans : true
  #     if contains(["Windows", "Linux", "WindowsContainer"], service_plan.os_type)
  #   ]) == length(var.service_plans)
  #   error_message = "Accepted OS type are [Windows], [Linux] or [WindowsContainer]."
  # }
}

# Windows App Service
variable "windows_web_apps" {
  type = list(
    object({
      name                = string
      location            = string
      resource_group_name = string
      service_plan_id     = optional(string)
      service_plan_name   = optional(string)

      site_config = object({
        always_on          = optional(bool)
        api_definition_url = optional(string)
        app_command_line   = optional(string)
        application_stack = optional(object({
          current_stack                = optional(string)
          docker_image_name            = optional(string)
          docker_registry_url          = optional(string)
          docker_registry_username     = optional(string)
          docker_registry_password     = optional(string)
          dotnet_version               = optional(string)
          dotnet_core_version          = optional(string)
          tomcat_version               = optional(string)
          java_embedded_server_enabled = optional(bool)
          java_version                 = optional(string)
          node_version                 = optional(string)
          php_version                  = optional(string)
          python                       = optional(bool)
        }))
        auto_heal_setting = optional(object({
          action = object({
            action_type = string
            custom_action = optional(object({
              executable = bool
              parameters = optional(string)
            }))
            minimum_process_execution_time = optional(string)
          })
          trigger = object({
            private_memory_kb = optional(number)
            requests = optional(object({
              count    = number
              interval = string
            }))
            slow_request = optional(object({
              count      = number
              interval   = string
              time_taken = string
            }))
            slow_request_with_path = optional(list(object({
              count      = number
              interval   = string
              time_taken = string
              path       = optional(string)
            })))
            status_code = optional(list(object({
              count             = number
              inetrval          = string
              status_code_range = string
              path              = optional(string)
              sub_status        = optional(string)
              win32_status_code = optional(string)
            })))
          })
        }))
        container_registry_managed_identity_client_id = optional(string)
        container_registry_use_managed_identity       = optional(string)
        cors = optional(object({
          allowed_origins     = optional(list(string))
          support_credentials = optional(bool)
        }))
        default_documents                 = optional(list(string))
        ftps_state                        = optional(string)
        health_check_path                 = optional(string)
        health_check_eviction_time_in_min = optional(number)
        http2_enabled                     = optional(bool)
        ip_restrictions = optional(list(object({
          action = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(number)
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
          ip_address                  = optional(string)
          name                        = optional(string)
          priority                    = optional(number)
          service_tag                 = optional(string)
          virtual_network_subnet_id   = optional(string)
          virtual_network_subnet_name = optional(string)
          description                 = optional(string)
        })))
        ip_restriction_default_action = optional(string)
        load_balancing_mode           = optional(string)
        local_mysql_enabled           = optional(bool)
        managed_pipeline_mode         = optional(string)
        minimum_tls_version           = optional(string)
        remote_debugging_enabled      = optional(bool)
        remote_debugging_version      = optional(string)
        scm_ip_restrictions = optional(list(object({
          action = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(number)
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
          ip_address                  = optional(string)
          name                        = optional(string)
          priority                    = optional(number)
          service_tag                 = optional(string)
          virtual_network_subnet_id   = optional(string)
          virtual_network_subnet_name = optional(string)
          description                 = optional(string)
        })))
        scm_ip_restriction_default_action = optional(string)
        scm_minimum_tls_version           = optional(string)
        scm_use_main_ip_restriction       = optional(bool)
        use_32_bit_worker                 = optional(bool)
        handler_mappings = optional(list(object({
          extension             = string
          script_processor_path = string
          arguments             = optional(string)
        })))
        virtual_applications = optional(list(object({
          physical_path = string
          preload       = bool
          virtual_directories = optional(list(object({
            physical_path = optional(string)
            virtual_path  = optional(string)
          })))
          virtual_path = string
        })))
        vnet_route_all_enabled = optional(bool)
        websockets_enabled     = optional(bool)
        worker_count           = optional(number)
      })

      app_settings = optional(map(any))
      auth_settings = optional(object({
        enabled = bool
        active_directory = optional(object({
          client_id                  = string
          allowed_audiences          = optional(list(string))
          client_secret              = optional(string)
          client_secret_setting_name = optional(string)
        }))
      }))
      auth_settings_v2 = optional(object({
        auth_enabled                          = optional(bool)
        runtime_version                       = optional(string)
        config_file_path                      = optional(string)
        require_authentication                = optional(bool)
        unauthenticated_action                = optional(string)
        default_provider                      = optional(string)
        excluded_paths                        = optional(string)
        require_https                         = optional(bool)
        http_route_api_prefix                 = optional(string)
        forward_proxy_convention              = optional(string)
        forward_proxy_custom_host_header_name = optional(string)
        apple_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          login_scopes               = optional(list(string))
        }))
        active_directory_v2 = optional(object({
          client_id                            = string
          tenant_auth_endpoint                 = string
          client_secret_setting_name           = optional(string)
          client_secret_certificate_thumbprint = optional(string)
          jwt_allowed_groups                   = optional(list(string))
          jwt_allowed_client_applications      = optional(list(string))
          www_authentication_disabled          = optional(bool)
          allowed_groups                       = optional(list(string))
          allowed_identities                   = optional(list(string))
          allowed_applications                 = optional(list(string))
          login_parameters                     = optional(map(any))
          allowed_audiences                    = optional(list(string))
        }))
        azure_static_web_app_v2 = optional(object({
          client_id = string
        }))
        custom_oidc_v2 = optional(object({
          name                          = string
          client_id                     = string
          openid_configuration_endpoint = string
          name_claim_type               = optional(string)
          scopes                        = optional(list(string))
          client_credential_method      = optional(string)
          client_secret_setting_name    = optional(string)
          authorisation_endpoint        = optional(string)
          token_endpoint                = optional(string)
          issuer_endpoint               = optional(string)
          certification_uri             = optional(string)
        }))
        facebook_v2 = optional(object({
          app_id                  = string
          app_secret_setting_name = string
          graph_api_version       = optional(string)
          login_scopes            = optional(list(string))
        }))
        github_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          login_scopes               = optional(list(string))
        }))
        google_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          allowed_audiences          = optional(list(string))
          login_scopes               = optional(list(string))
        }))
        microsoft_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          allowed_audiences          = optional(list(string))
          login_scopes               = optional(list(string))
        }))
        twitter_v2 = optional(object({
          consumer_key                 = string
          consumer_secret_setting_name = string
        }))
        login = object({
          logout_endpoint                   = optional(string)
          token_store_enabled               = optional(bool)
          token_refresh_extension_time      = optional(number)
          token_store_path                  = optional(string)
          token_store_sas_setting_name      = optional(string)
          preserve_url_fragments_for_logins = optional(bool)
          allowed_external_redirect_urls    = optional(list(string))
          cookie_expiration_convention      = optional(string)
          cookie_expiration_time            = optional(string)
          validate_nonce                    = optional(bool)
          nonce_expiration_time             = optional(string)
        })
      }))
      backup = optional(object({
        name = string
        schedule = object({
          frequency_interval       = number
          frequency_unit           = string
          keep_at_least_one_backup = optional(bool)
          retention_period_days    = optional(number)
          start_time               = optional(string)
        })
        storage_account_url = string
        enabled             = optional(bool)
      }))
      client_affinity_enabled            = optional(bool)
      client_certificate_enabled         = optional(bool)
      client_certificate_mode            = optional(string)
      client_certificate_exclusion_paths = optional(string)
      connection_strings = optional(list(object({
        name  = string
        type  = string
        value = string
      })))
      enabled                                  = optional(bool)
      ftp_publish_basic_authentication_enabled = optional(bool)
      https_only                               = optional(bool)
      public_network_access_enabled            = optional(bool)
      identity = optional(object({
        type           = string
        identity_ids   = optional(list(string))
        identity_names = optional(list(string))
      }))
      key_vault_reference_identity_id = optional(string)
      logs = optional(object({
        application_logs = optional(object({
          azure_blob_storage = optional(object({
            level             = string
            retention_in_days = number
            sas_url           = string
          }))
          file_system_level = string
        }))
        detailed_error_messages = optional(bool)
        failed_request_tracing  = optional(bool)
        http_logs = optional(object({
          azure_blob_storage = optional(object({
            retention_in_days = optional(number)
            sas_url           = optional(string)
          }))
          file_system = optional(object({
            retention_in_days = number
            retention_in_mb   = number
          }))
        }))
      }))
      sticky_settings = optional(object({
        app_setting_names       = optional(list(string))
        connection_string_names = optional(list(string))
      }))
      storage_accounts = optional(list(object({
        access_key   = string
        account_name = string
        name         = string
        share_name   = string
        type         = string
        mount_path   = string
      })))
      tags = optional(map(any))
      # virtual_network_backup_restore_enabled         = optional(bool)
      virtual_network_subnet_id                      = optional(string)
      virtual_network_subnet_name                    = optional(string)
      webdeploy_publish_basic_authentication_enabled = optional(bool)
      zip_deploy_file                                = optional(string)

      private_endpoints = optional(list(object({
        name                          = string
        custom_network_interface_name = optional(string)

        subresource_name = string
        member_name      = optional(string)

        ip_configuration = object({
          private_ip_address = string
        })

        # Subnet
        subnet_name = optional(string)
        subnet_id   = optional(string)

        private_dns_zone_names = optional(list(string))
        private_dns_zone_ids   = optional(list(string))
      })))
    })
  )
  default = null
}

variable "windows_function_apps" {
  type = list(
    object({
      name                = string
      location            = string
      resource_group_name = string
      service_plan_id     = optional(string)
      service_plan_name   = optional(string)

      site_config = object({
        always_on                              = optional(bool)
        api_definition_url                     = optional(string)
        api_management_api_id                  = optional(string)
        app_command_line                       = optional(string)
        app_scale_limit                        = optional(number)
        application_insights_connection_string = optional(string)
        application_insights_key               = optional(string)
        application_stack = optional(object({
          dotnet_version              = optional(string)
          use_dotnet_isolated_runtime = optional(bool)
          java_version                = optional(string)
          node_version                = optional(string)
          powershell_core_version     = optional(string)
          use_custom_runtime          = optional(bool)
        }))
        app_service_logs = optional(object({
          disk_quota_mb         = optional(number)
          retention_period_days = optional(number)
        }))
        cors = optional(object({
          allowed_origins     = optional(list(string))
          support_credentials = optional(bool)
        }))
        default_documents                 = optional(list(string))
        elastic_instance_minimum          = optional(number)
        ftps_state                        = optional(string)
        health_check_path                 = optional(string)
        health_check_eviction_time_in_min = optional(number)
        http2_enabled                     = optional(bool)
        ip_restrictions = optional(list(object({
          action = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(number)
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
          ip_address                  = optional(string)
          name                        = optional(string)
          priority                    = optional(number)
          service_tag                 = optional(string)
          virtual_network_subnet_id   = optional(string)
          virtual_network_subnet_name = optional(string)
          description                 = optional(string)
        })))
        ip_restriction_default_action    = optional(string)
        load_balancing_mode              = optional(string)
        managed_pipeline_mode            = optional(string)
        minimum_tls_version              = optional(string)
        pre_warmed_instance_count        = optional(number)
        remote_debugging_enabled         = optional(bool)
        remote_debugging_version         = optional(string)
        runtime_scale_monitoring_enabled = optional(bool)
        scm_ip_restrictions = optional(list(object({
          action = optional(string)
          headers = optional(object({
            x_azure_fdid      = optional(list(string))
            x_fd_health_probe = optional(number)
            x_forwarded_for   = optional(list(string))
            x_forwarded_host  = optional(list(string))
          }))
          ip_address                  = optional(string)
          name                        = optional(string)
          priority                    = optional(number)
          service_tag                 = optional(string)
          virtual_network_subnet_id   = optional(string)
          virtual_network_subnet_name = optional(string)
          description                 = optional(string)
        })))
        scm_ip_restriction_default_action = optional(string)
        scm_minimum_tls_version           = optional(string)
        scm_use_main_ip_restriction       = optional(bool)
        use_32_bit_worker                 = optional(bool)
        vnet_route_all_enabled            = optional(bool)
        websockets_enabled                = optional(bool)
        worker_count                      = optional(number)
      })
      app_settings = optional(map(any))
      auth_settings = optional(object({
        enabled = bool
        active_directory = optional(object({
          client_id                  = string
          allowed_audiences          = optional(list(string))
          client_secret              = optional(string)
          client_secret_setting_name = optional(string)
        }))
        allowed_external_redirect_urls = optional(string)
        default_provider               = optional(string)
        facebook = optional(object({
          app_id                  = string
          app_secret              = optional(string)
          app_secret_setting_name = optional(string)
          oauth_scopes            = optional(list(string))
        }))
        github = optional(object({
          client_id                  = string
          client_secret              = optional(string)
          client_secret_setting_name = optional(string)
          oauth_scopes               = optional(list(string))
        }))
        google = optional(object({
          client_id                  = string
          client_secret              = optional(string)
          client_secret_setting_name = optional(string)
          oauth_scopes               = optional(list(string))
        }))
        issuer = optional(string)
        microsoft = optional(object({
          client_id                  = string
          client_secret              = optional(string)
          client_secret_setting_name = optional(string)
          oauth_scopes               = optional(list(string))
        }))
        runtime_version               = optional(string)
        token_refresh_extension_hours = optional(number)
        token_store_enabled           = optional(bool)
        twitter = optional(object({
          consumer_key                 = string
          consumer_secret              = optional(string)
          consumer_secret_setting_name = optional(string)
        }))
        unauthenticated_client_action = optional(string)
      }))
      auth_settings_v2 = optional(object({
        auth_enabled                            = optional(bool)
        runtime_version                         = optional(string)
        config_file_path                        = optional(string)
        require_authentication                  = optional(bool)
        unauthenticated_action                  = optional(string)
        default_provider                        = optional(string)
        excluded_paths                          = optional(string)
        require_https                           = optional(bool)
        http_route_api_prefix                   = optional(string)
        forward_proxy_convention                = optional(string)
        forward_proxy_custom_host_header_name   = optional(string)
        forward_proxy_custom_scheme_header_name = optional(string)
        apple_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          login_scopes               = optional(list(string))
        }))
        active_directory_v2 = optional(object({
          client_id                            = string
          tenant_auth_endpoint                 = string
          client_secret_setting_name           = optional(string)
          client_secret_certificate_thumbprint = optional(string)
          jwt_allowed_groups                   = optional(list(string))
          jwt_allowed_client_applications      = optional(list(string))
          www_authentication_disabled          = optional(bool)
          allowed_groups                       = optional(list(string))
          allowed_identities                   = optional(list(string))
          allowed_applications                 = optional(list(string))
          login_parameters                     = optional(map(any))
          allowed_audiences                    = optional(list(string))
        }))
        azure_static_web_app_v2 = optional(object({
          client_id = string
        }))
        custom_oidc_v2 = optional(object({
          name                          = string
          client_id                     = string
          openid_configuration_endpoint = string
          name_claim_type               = optional(string)
          scopes                        = optional(list(string))
          client_credential_method      = optional(string)
          client_secret_setting_name    = optional(string)
          authorisation_endpoint        = optional(string)
          token_endpoint                = optional(string)
          issuer_endpoint               = optional(string)
          certification_uri             = optional(string)
        }))
        facebook_v2 = optional(object({
          app_id                  = string
          app_secret_setting_name = string
          graph_api_version       = optional(string)
          login_scopes            = optional(list(string))
        }))
        github_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          login_scopes               = optional(list(string))
        }))
        google_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          allowed_audiences          = optional(list(string))
          login_scopes               = optional(list(string))
        }))
        microsoft_v2 = optional(object({
          client_id                  = string
          client_secret_setting_name = string
          allowed_audiences          = optional(list(string))
          login_scopes               = optional(list(string))
        }))
        twitter_v2 = optional(object({
          consumer_key                 = string
          consumer_secret_setting_name = string
        }))
        login = object({
          logout_endpoint                   = optional(string)
          token_store_enabled               = optional(bool)
          token_refresh_extension_time      = optional(number)
          token_store_path                  = optional(string)
          token_store_sas_setting_name      = optional(string)
          preserve_url_fragments_for_logins = optional(bool)
          allowed_external_redirect_urls    = optional(list(string))
          cookie_expiration_convention      = optional(string)
          cookie_expiration_time            = optional(string)
          validate_nonce                    = optional(bool)
          nonce_expiration_time             = optional(string)
        })
      }))
      backup = optional(object({
        name = string
        schedule = object({
          frequency_interval       = number
          frequency_unit           = string
          keep_at_least_one_backup = optional(bool)
          retention_period_days    = optional(number)
          start_time               = optional(string)
        })
        storage_account_url = string
        enabled             = optional(bool)
      }))
      builtin_logging_enabled            = optional(string)
      client_certificate_enabled         = optional(bool)
      client_certificate_mode            = optional(string)
      client_certificate_exclusion_paths = optional(string)
      connection_strings = optional(list(object({
        name  = string
        type  = string
        value = string
      })))
      content_share_force_disabled             = optional(string)
      daily_memory_time_quota                  = optional(number)
      enabled                                  = optional(bool)
      ftp_publish_basic_authentication_enabled = optional(bool)
      functions_extension_version              = optional(string)
      https_only                               = optional(bool)
      public_network_access_enabled            = optional(bool)
      identity = optional(object({
        type           = string
        identity_ids   = optional(list(string))
        identity_names = optional(list(string))
      }))
      key_vault_reference_identity_id   = optional(string)
      key_vault_reference_identity_name = optional(string)
      storage_accounts = optional(list(object({
        access_key   = string
        account_name = string
        name         = string
        share_name   = string
        type         = string
        mount_path   = string
      })))
      sticky_settings = optional(object({
        app_setting_names       = optional(list(string))
        connection_string_names = optional(list(string))
      }))
      storage_account_access_key    = optional(string)
      storage_account_name          = optional(string)
      storage_uses_managed_identity = optional(bool)
      storage_key_vault_secret_id   = optional(string)
      tags                          = optional(map(any))
      # virtual_network_backup_restore_enabled         = optional(bool)
      virtual_network_subnet_id                      = optional(string)
      virtual_network_subnet_name                    = optional(string)
      vnet_image_pull_enabled                        = optional(bool)
      webdeploy_publish_basic_authentication_enabled = optional(bool)
      zip_deploy_file                                = optional(string)

      private_endpoints = optional(list(object({
        name                          = string
        custom_network_interface_name = optional(string)

        subresource_name = string
        member_name      = optional(string)

        ip_configuration = object({
          private_ip_address = string
        })

        # Subnet
        subnet_name = optional(string)
        subnet_id   = optional(string)

        private_dns_zone_names = optional(list(string))
        private_dns_zone_ids   = optional(list(string))
      })))
    })
  )
  default = null
}

variable "monitor_diagnostic_settings" {
  type = list(object({
    name                      = string
    storage_sub_resource_name = optional(string)
    target_resource_id        = optional(string)
    target_resource_module    = optional(string)
    target_resource_name      = optional(string)

    eventhub_name                  = optional(string)
    eventhub_authorization_rule_id = optional(string)

    log_analytics_workspace_name = optional(string)
    log_analytics_workspace_id   = optional(string)

    storage_account_name = optional(string)
    storage_account_id   = optional(string)

    partner_solution_id            = optional(string)
    log_analytics_destination_type = optional(string)

    enabled_log = optional(list(object({
      category       = optional(string)
      category_group = optional(string)
    })))

    metric = optional(list(object({
      category = string
      enabled  = optional(bool)
    })))
  }))
  default = null
}

variable "recovery_services_vaults" {
  type = list(object({
    name                               = string
    location                           = optional(string)
    resource_group_name                = optional(string)
    sku                                = string
    public_network_access_enabled      = optional(bool)
    immutability                       = optional(bool)
    storage_mode_type                  = optional(string)
    cross_region_restore_enabled       = optional(string)
    soft_delete_enabled                = optional(bool)
    classic_vmware_replication_enabled = optional(bool)

    encryption = optional(object({
      key_id                            = string
      infrastructure_encryption_enabled = string
      user_assigned_identity_id         = optional(string)
      use_system_assigned_identity      = optional(bool)
    }))

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    monitoring = optional(object({
      alerts_for_all_job_failures_enabled            = optional(bool)
      alerts_for_critical_operation_failures_enabled = optional(bool)
    }))

    backup_policy_vm = optional(list(object({
      name                           = string
      resource_group_name            = optional(string)
      recovery_vault_name            = optional(string)
      policy_type                    = optional(string)
      timezone                       = optional(string)
      instant_restore_retention_days = optional(number)
      backup = object({
        frequency     = string
        time          = string
        hour_interval = optional(number)
        hour_duration = optional(number)
      })
      retention_daily = optional(object({
        count = number
      }))
      retention_weekly = optional(object({
        count    = number
        weekdays = optional(set(string))
      }))
      retention_monthly = optional(object({
        count             = number
        weekdays          = optional(set(string))
        weeks             = optional(set(string))
        days              = optional(set(number))
        include_last_days = optional(bool)
      }))
      retention_yearly = optional(object({
        count             = number
        months            = set(string)
        weekdays          = optional(set(string))
        weeks             = optional(set(string))
        days              = optional(set(number))
        include_last_days = optional(bool)
      }))
      instant_restore_resource_group = optional(object({
        prefix = string
        suffix = optional(string)
      }))
    })))
  }))

  default = null
}

variable "cdn_frontdoor_profiles" {
  type = list(object({
    name                = string
    resource_group_name = string
    sku_name            = string

    identity = optional(object({
      type           = string
      identity_ids   = optional(list(string))
      identity_names = optional(list(string))
    }))

    response_timeout_seconds = optional(string)
    tags                     = optional(map(any))

    cdn_frontdoor_endpoints = list(object({
      name    = string
      enabled = optional(bool)
      tags    = optional(map(any))
    }))

    cdn_frontdoor_origin_groups = list(object({
      name = string
      load_balancing = object({
        additional_latency_in_milliseconds = optional(number)
        sample_size                        = optional(number)
        successful_samples_required        = optional(number)
      })
      health_probe = optional(object({
        protocol            = string
        interval_in_seconds = number
        request_type        = optional(string)
        path                = optional(string)
      }))
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number)
      session_affinity_enabled                                  = optional(bool)

      cdn_frontdoor_origins = list(object({
        name                           = string
        host_name                      = string
        certificate_name_check_enabled = bool
        enabled                        = optional(bool)
        http_port                      = optional(number)
        https_port                     = optional(number)
        origin_host_header             = optional(string)
        priority                       = optional(number)
        private_link = optional(object({
          request_message        = optional(string)
          target_type            = optional(string)
          location               = string
          private_link_target_id = string
        }))
        weight = optional(number)
      }))
    }))

    cdn_frontdoor_routes = list(object({
      name                              = string
      cdn_frontdoor_endpoint_id         = optional(string)
      cdn_frontdoor_endpoint_name       = optional(string)
      cdn_frontdoor_origin_group_id     = optional(string)
      cdn_frontdoor_origin_group_name   = optional(string)
      cdn_frontdoor_origin_ids          = optional(list(string))
      cdn_frontdoor_origin_names        = optional(list(string))
      forwarding_protocol               = optional(string)
      patterns_to_match                 = list(string)
      supported_protocols               = list(string)
      cdn_frontdoor_custom_domain_ids   = optional(list(string))
      cdn_frontdoor_custom_domain_names = optional(list(string))
      cdn_frontdoor_origin_path         = optional(string)
      cdn_frontdoor_rule_set_ids        = optional(list(string))
      enabled                           = optional(bool)
      https_redirect_enabled            = optional(bool)
      link_to_default_domain            = optional(bool)

      cache = optional(object({
        query_string_caching_behavior = optional(string)
        query_strings                 = optional(string)
        compression_enabled           = optional(bool)
        content_types_to_compress     = optional(list(string))
      }))
    }))

    cdn_frontdoor_custom_domains = optional(list(object({
      name        = string
      host_name   = string
      dns_zone_id = optional(string)
      tls = object({
        certificate_type          = optional(string)
        minimum_tls_version       = optional(string)
        cdn_frontdoor_secret_id   = optional(string)
        cdn_frontdoor_secret_name = optional(string)
      })
      cdn_frontdoor_route_names = optional(list(string))
    })))

    cdn_frontdoor_firewall_policies = optional(list(object({
      name                                      = string
      resource_group_name                       = string
      sku_name                                  = string
      enabled                                   = optional(bool)
      js_challenge_cookie_expiration_in_minutes = optional(number)
      mode                                      = string
      request_body_check_enabled                = optional(bool)
      redirect_url                              = optional(string)
      custom_rules = optional(list(object({
        name     = string
        action   = string
        enabled  = optional(bool)
        priority = optional(number)
        type     = optional(string)
        match_conditions = optional(list(object({
          match_variable     = string
          match_values       = list(string)
          operator           = string
          selector           = optional(string)
          negation_condition = optional(bool)
          transforms         = optional(list(string))
        })))
        rate_limit_duration_in_minutes = optional(number)
        rate_limit_threshold           = optional(number)
      })))
      custom_block_response_status_code = optional(string)
      custom_block_response_body        = optional(string)
      log_scrubbing = optional(object({
        enabled = optional(bool)
        scrubbing_rules = optional(list(object({
          match_variable = string
          selector       = optional(string)
          operator       = optional(string)
          enabled        = optional(string)
        })))
      }))
      managed_rules = optional(list(object({
        type    = string
        version = string
        action  = string
        exclusions = optional(list(object({
          match_variable = string
          operator       = string
          selector       = string
        })))
        overrides = optional(list(object({
          rule_group_name = string
          exclusions = optional(list(object({
            match_variable = string
            operator       = string
            selector       = string
          })))
          rules = optional(list(object({
            rule_id = string
            action  = string
            enabled = optional(bool)
            exclusions = optional(list(object({
              match_variable = string
              operator       = string
              selector       = string
            })))
          })))
        })))
      })))
      tags = optional(map(any))
    })))

    cdn_frontdoor_security_policies = optional(list(object({
      name = string
      security_policies = object({
        firewall = object({
          cdn_frontdoor_firewall_policy_id   = optional(string)
          cdn_frontdoor_firewall_policy_name = optional(string)
          association = object({
            domains = list(object({
              cdn_frontdoor_domain_id   = optional(string)
              cdn_frontdoor_domain_name = optional(string)
              cdn_frontdoor_domain_type = optional(string)
            }))
            patterns_to_match = list(string)
          })
        })
      })
    })))

    cdn_frontdoor_secret = optional(list(object({
      name = string
      secret = object({
        customer_certificate = object({
          key_vault_certificate_id = string
        })
      })
    })))
  }))

  default = null
}

variable "monitor_activity_log_alerts" {
  type = list(object({
    name                = string
    resource_group_name = string
    location            = string
    scopes              = list(string)
    criteria = object({
      category                = string
      caller                  = optional(string)
      operation_name          = optional(string)
      resource_provider       = optional(string)
      resource_providers      = optional(list(string))
      resource_type           = optional(string)
      resource_types          = optional(list(string))
      resource_group          = optional(string)
      resource_groups         = optional(list(string))
      resource_id             = optional(string)
      resource_ids            = optional(list(string))
      level                   = optional(string)
      levels                  = optional(list(string))
      status                  = optional(string)
      statuses                = optional(list(string))
      sub_status              = optional(string)
      sub_statuses            = optional(list(string))
      recommendation_type     = optional(string)
      recommendation_category = optional(string)
      recommendation_impact   = optional(string)
      resource_health = optional(object({
        current  = optional(string)
        previous = optional(string)
        reason   = optional(string)
      }))
      service_health = optional(object({
        events    = optional(string)
        locations = optional(string)
        services  = optional(string)
      }))
    })
    action = optional(list(object({
      action_group_id    = optional(string)
      action_group_name  = optional(string)
      webhook_properties = optional(map(string))
    })))
    enabled     = optional(bool)
    description = optional(string)
    tags        = optional(map(any))
  }))
  default = null
}

variable "action_groups" {
  type = list(object({
    name                = string
    resource_group_name = string
    short_name          = string
    enabled             = optional(bool)
    location            = optional(string)

    arm_role_receivers = optional(list(object({
      name                    = string
      role_id                 = string
      use_common_alert_schema = optional(bool)
    })))

    automation_runbook_receivers = optional(list(object({
      name                    = string
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      is_global_runbook       = bool
      service_uri             = string
      use_common_alert_schema = optional(bool)
    })))

    azure_app_push_receivers = optional(list(object({
      name          = string
      email_address = string
    })))

    azure_function_receivers = optional(list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool)
    })))

    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool)
    })))

    event_hub_receivers = optional(list(object({
      name                    = string
      event_hub_name          = optional(string)
      event_hub_namespace     = optional(string)
      subscription_id         = optional(string)
      tenant_id               = optional(string)
      use_common_alert_schema = optional(bool)
    })))

    itsm_receivers = optional(list(object({
      name                 = string
      workspace_id         = string
      connection_id        = string
      ticket_configuration = string
      region               = string
    })))

    logic_app_receivers = optional(list(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool)
    })))

    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })))

    voice_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })))

    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool)
      aad_auth = optional(object({
        object_id      = string
        identifier_uri = optional(string)
        tenant_id      = optional(string)
      }))
    })))
  }))
  default = null
}

variable "security_center_contacts" {
  type = list(object({
    name                = string
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool)
    alerts_to_admins    = optional(bool)
  }))
  default = null
}

variable "public_ips" {
  type = list(
    object({
      name                = string
      resource_group_name = string
      location            = string
      allocation_method   = string
      #zones                  = optional(list(string)) 
      ddos_protection_mode    = optional(string)
      ddos_protection_plan_id = optional(string)
      domain_name_label       = optional(string)
      domain_name_label_scope = optional(string)
      edge_zone               = optional(string)
      idle_timeout_in_minutes = optional(string)
      ip_tags                 = optional(map(any))
      ip_version              = optional(string)
      public_ip_prefix_id     = optional(string)
      reverse_fqdn            = optional(string)
      sku                     = optional(string)
      sku_tier                = optional(string)
      tags                    = optional(map(any))
    })
  )
  default = null
}

variable "mongo_private_endpoints" {
  type = list(
    object({
      name                           = string
      resource_group_name            = string
      location                       = string
      subnet_name                    = string
      private_connection_name        = string
      private_connection_resource_id = string
      is_manual_connection           = optional(bool, true)
      subresource_names              = optional(list(string))
      request_message                = optional(string)
      private_dns_zone_names         = optional(list(string))
      tags                           = optional(map(any))
    })
  )
  default = null
}

variable "vm_shutdown_schedules" {
  type = list(
    object({
      location              = string
      virtual_machine_name  = string
      enabled               = optional(bool)
      timezone              = string
      daily_recurrence_time = string

      notification_settings = object({
        enabled         = bool
        email           = optional(string)
        time_in_minutes = optional(string)
        webhook_url     = optional(string)
      })
      tags = optional(map(any))
    })
  )
  default = null
}

variable "automation_accounts" {
  type = list(
    object({
      name                          = string
      location                      = string
      resource_group_name           = string
      sku_name                      = string
      local_authentication_enabled  = optional(bool)
      public_network_access_enabled = optional(bool)
      identity = optional(object({
        type                   = string
        user_assigned_identity = optional(list(string))
      }))
      tags = optional(map(any))
      encryption = optional(object({
        key_vault_key_name     = string
        user_assigned_identity = optional(list(string))
      }))

      automation_schedules = optional(list(object({
        name                    = string
        resource_group_name     = optional(string)
        automation_account_name = optional(string)
        frequency               = string
        description             = optional(string)
        interval                = optional(number)
        start_time              = optional(string)
        expiry_time             = optional(string)
        timezone                = optional(string)
        week_days               = optional(list(string))
        month_days              = optional(list(number))
        monthly_occurrence = optional(object({
          day        = string
          occurrence = number
        }))
      })))

      automation_runbooks = optional(list(object({
        name                    = string
        location                = string
        resource_group_name     = string
        automation_account_name = string
        runbook_type            = string
        log_progress            = bool
        log_verbose             = bool
        publish_content_link = optional(object({
          uri     = string
          version = optional(string)
          hash = optional(object({
            algorithm = string
            value     = string
          }))
        }))
        description              = optional(string)
        content                  = optional(string)
        filename                 = optional(string)
        tags                     = optional(map(any))
        log_activity_trace_level = optional(string)
        draft = optional(object({
          edit_mode_enabled = optional(bool)
          content_link = optional(object({
            uri     = string
            version = optional(string)
            hash = optional(object({
              algorithm = string
              value     = string
            }))
          }))
          output_types = optional(string)
          parameters = optional(list(object({
            key           = string
            type          = string
            mandatory     = optional(bool)
            position      = optional(string)
            default_value = optional(string)
          })))
        }))

        job_schedules = optional(list(object({
          schedule_name           = string
          resource_group_name     = optional(string)
          automation_account_name = optional(string)
          runbook_name            = optional(string)
          parameters              = optional(map(string))
          run_on                  = optional(string)
        })))
      })))
    })
  )
  default = null
}

variable "consumption_budget_subscription" {
  type = list(object({
    name            = string
    subscription_id = optional(string)
    amount          = number
    time_grain      = optional(string)
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    notifications = list(object({
      operator       = string
      threshold      = number
      threshold_type = optional(string)
      contact_emails = optional(list(string))
      contact_groups = optional(list(string))
      contact_roles  = optional(list(string))
      enabled        = optional(bool)
    }))
    filter = optional(object({
      dimensions = optional(list(object({
        name     = string
        operator = optional(string)
        values   = list(string)
      })))
      tags = optional(list(object({
        name     = string
        operator = optional(string)
        values   = list(string)
      })))
    }))
  }))
  default = null
}

variable "log_analytics_workspaces" {
  type = list(object({
    name                            = string
    resource_group_name             = string
    location                        = string
    allow_resource_only_permissions = optional(bool)
    local_authentication_enabled    = optional(bool)
    sku                             = optional(string)
    retention_in_days               = optional(number)
    daily_quota_gb                  = optional(number)
    cmk_for_query_forced            = optional(bool)
    identity = optional(object({
      type           = string
      identity_ids   = optional(list(string))
      identity_names = optional(list(string))
    }))
    internet_ingestion_enabled              = optional(bool)
    internet_query_enabled                  = optional(bool)
    reservation_capacity_in_gb_per_day      = optional(number)
    data_collection_rule_id                 = optional(string)
    immediate_data_purge_on_30_days_enabled = optional(bool)
    tags                                    = optional(map(any))
  }))
  default = null
}

# Backup Vaults
variable "data_protection_backup_vaults" {
  type = list(object({
    name                         = string
    resource_group_name          = string
    location                     = string
    datastore_type               = string
    redundancy                   = string
    cross_region_restore_enabled = optional(bool)
    identity = optional(object({
      type = string
    }))
    retention_duration_in_days = optional(number)
    immutability               = optional(bool)
    soft_delete                = optional(string)
    tags                       = optional(map(any))
  }))
  default = null
}

# Backup policy for Blob Storage
variable "data_protection_backup_policies_blob_storage" {
  type = list(object({
    name                                   = string
    vault_name                             = optional(string)
    vault_id                               = optional(string)
    backup_repeating_time_intervals        = optional(list(string))
    operational_default_retention_duration = optional(string)
    retention_rule = optional(list(object({
      name = string
      criteria = object({
        absolute_criteria      = optional(string)
        days_of_month          = optional(set(number))
        days_of_week           = optional(set(string))
        months_of_year         = optional(set(string))
        scheduled_backup_times = optional(list(string))
        weeks_of_month         = optional(set(string))
      })
      life_cycle = object({
        data_store_type = string
        duration        = string
      })
      priority = number
    })))
    time_zone                        = optional(string)
    vault_default_retention_duration = optional(string)
  }))
  default = null
}

# Backup instance for Blob Storage
variable "data_protection_backup_instances_blob_storage" {
  type = list(object({
    name                            = string
    location                        = string
    vault_name                      = optional(string)
    vault_id                        = optional(string)
    storage_account_name            = optional(string)
    storage_account_id              = optional(string)
    backup_policy_name              = optional(string)
    backup_policy_id                = optional(string)
    storage_account_container_names = optional(list(string))
  }))
  default = null
}

# MySQL Flexible Server
variable "mysql_flexible_servers" {
  type = list(object({
    name                         = string
    resource_group_name          = string
    location                     = string
    backup_retention_days        = optional(number)
    geo_redundant_backup_enabled = optional(bool)
    sku_name                     = string
    version                      = string
    zone                         = optional(string)

    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))

    maintenance_window = optional(object({
      day_of_week  = optional(number)
      start_hour   = optional(number)
      start_minute = optional(number)
    }))

    storage = optional(object({
      auto_grow_enabled = optional(bool)
      iops              = optional(number)
      size_gb           = optional(number)
    }))

    identity = optional(object({
      type           = string
      identity_ids   = optional(list(string))
      identity_names = optional(list(string))
    }))

    customer_managed_key = optional(object({
      key_vault_key_id                     = optional(string)
      primary_user_assigned_identity_id    = optional(string)
      geo_backup_key_vault_key_id          = optional(string)
      geo_backup_user_assigned_identity_id = optional(string)
    }))

    delegated_subnet_id   = optional(string)
    private_dns_zone_id   = optional(string)
    public_network_access = optional(string)

    configurations = optional(list(object({
      name                = string
      resource_group_name = string
      value               = string
    })))

    firewall_rules = optional(list(object({
      name                = string
      resource_group_name = string
      start_ip_address    = string
      end_ip_address      = string
    })))

    databases = optional(list(object({
      name                = string
      resource_group_name = string
      charset             = string
      collation           = string
    })))

    private_endpoints = optional(list(object({
      name                          = string
      location                      = optional(string)
      resource_group_name           = optional(string)
      custom_network_interface_name = optional(string)
      subnet_name                   = string
      member_name                   = optional(string)
      ip_configuration = optional(object({
        private_ip_address = string
      }))
      private_dns_zone_names = optional(list(string))
      tags                   = optional(map(string))
    })))

    tags = optional(map(string))
  }))
  default = null
}

variable "mysql_flexible_servers_administrator_login" {
  type      = string
  sensitive = true
  default   = ""
}

variable "mysql_flexible_servers_administrator_password" {
  type      = string
  sensitive = true
  default   = ""
}

# Azure Kubernetes Service
variable "kubernetes_clusters" {
  type = list(object({
    name                                      = string
    location                                  = string
    resource_group_name                       = string
    dns_prefix                                = optional(string)
    kubernetes_version                        = optional(string)
    sku_tier                                  = optional(string)
    automatic_upgrade_channel                 = optional(string)
    node_os_upgrade_channel                   = optional(string)
    private_cluster_enabled                   = optional(bool)
    private_dns_zone_id                       = optional(string)
    private_cluster_public_fqdn_enabled       = optional(bool)
    azure_policy_enabled                      = optional(bool)
    http_application_routing_enabled          = optional(bool)
    role_based_access_control_enabled         = optional(bool)
    attach_acr_names                          = optional(list(string))
    allow_identity_access_user                = optional(list(string))
    allow_identity_access_admin               = optional(list(string))
    allow_identity_access_contributor         = optional(list(string))
    allow_principal_access_admin              = optional(list(string))
    allow_identity_subnet_network_contributor = optional(list(string))
    # Set to true to grant Network Contributor on the AKS default node pool subnet
    # to the AKS cluster's own identity (SystemAssigned or UserAssigned).
    # Required to resolve: LinkedAuthorizationFailed - Microsoft.Network/virtualNetworks/subnets/join/action
    # which occurs when AKS provisions an internal LoadBalancer service.
    grant_subnet_network_contributor = optional(bool)

    default_node_pool = object({
      name                         = string
      vm_size                      = string
      node_count                   = optional(number)
      enable_auto_scaling          = optional(bool)
      min_count                    = optional(number)
      max_count                    = optional(number)
      max_pods                     = optional(number)
      os_disk_size_gb              = optional(number)
      os_disk_type                 = optional(string)
      subnet_name                  = string
      zones                        = optional(list(string))
      enable_host_encryption       = optional(bool)
      enable_node_public_ip        = optional(bool)
      orchestrator_version         = optional(string)
      temporary_name_for_rotation  = optional(string)
      only_critical_addons_enabled = optional(bool)
      upgrade_settings = optional(object({
        max_surge                     = string
        drain_timeout_in_minutes      = optional(number)
        node_soak_duration_in_minutes = optional(number)
      }))
      tags = optional(map(string))
    })

    identity = optional(object({
      type           = string
      identity_ids   = optional(list(string))
      identity_names = optional(list(string))
    }))

    network_profile = optional(object({
      network_plugin      = string
      network_policy      = optional(string)
      dns_service_ip      = optional(string)
      service_cidr        = optional(string)
      load_balancer_sku   = optional(string)
      outbound_type       = optional(string)
      network_plugin_mode = optional(string)
    }))

    azure_active_directory_role_based_access_control = optional(object({
      azure_rbac_enabled     = optional(bool)
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string))
    }))

    oms_agent = optional(object({
      log_analytics_workspace_id      = optional(string)
      msi_auth_for_monitoring_enabled = optional(bool)
    }))

    # Set to true to create a Data Collection Rule (DCR) and associate it with this
    # AKS cluster, enabling ContainerLogV2 ingestion into the Log Analytics workspace
    # defined in oms_agent.log_analytics_workspace_id.
    enable_container_insights             = optional(bool)
    container_insights_dcr_name           = optional(string)
    container_insights_interval           = optional(string)
    container_insights_exclude_namespaces = optional(list(string))

    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool)
      secret_rotation_interval = optional(string)
    }))

    maintenance_window = optional(object({
      allowed = optional(list(object({
        day   = string
        hours = list(number)
      })))
      not_allowed = optional(list(object({
        start = string
        end   = string
      })))
    }))

    maintenance_window_auto_upgrade = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      week_index   = optional(string)
      day_of_month = optional(number)
      start_time   = string
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed = optional(list(object({
        start = string
        end   = string
      })))
    }))

    maintenance_window_node_os = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      week_index   = optional(string)
      day_of_month = optional(number)
      start_time   = string
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed = optional(list(object({
        start = string
        end   = string
      })))
    }))

    microsoft_defender = optional(object({
      log_analytics_workspace_id = string
    }))

    monitor_metrics = optional(object({
      annotations_allowed = optional(string)
      labels_allowed      = optional(string)
    }))

    enable_prometheus      = optional(bool)
    monitor_workspace_name = optional(string)
    prometheus_dcr_name    = optional(string)
    prometheus_dce_name    = optional(string)

    service_mesh_profile = optional(object({
      mode                             = string
      revisions                        = list(string)
      internal_ingress_gateway_enabled = optional(bool)
      external_ingress_gateway_enabled = optional(bool)
    }))

    additional_node_pools = optional(list(object({
      name                        = string
      vm_size                     = string
      node_count                  = optional(number)
      enable_auto_scaling         = optional(bool)
      min_count                   = optional(number)
      max_count                   = optional(number)
      max_pods                    = optional(number)
      os_disk_size_gb             = optional(number)
      os_disk_type                = optional(string)
      subnet_name                 = optional(string)
      zones                       = optional(list(string))
      enable_host_encryption      = optional(bool)
      enable_node_public_ip       = optional(bool)
      orchestrator_version        = optional(string)
      temporary_name_for_rotation = optional(string)
      node_taints                 = optional(list(string))
      node_labels                 = optional(map(string))
      upgrade_settings = optional(object({
        max_surge                     = string
        drain_timeout_in_minutes      = optional(number)
        node_soak_duration_in_minutes = optional(number)
      }))
      tags = optional(map(string))
    })))

    tags = optional(map(string))
  }))
  default = null
}

# Azure Container Registry
variable "container_registries" {
  type = list(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    sku                           = string
    admin_enabled                 = optional(bool)
    public_network_access_enabled = optional(bool)
    zone_redundancy_enabled       = optional(bool)
    export_policy_enabled         = optional(bool)
    quarantine_policy_enabled     = optional(bool)
    retention_policy_in_days      = optional(number)
    trust_policy_enabled          = optional(bool)
    data_endpoint_enabled         = optional(bool)
    network_rule_bypass_option    = optional(string)

    identity = optional(object({
      type           = string
      identity_ids   = optional(list(string))
      identity_names = optional(list(string))
    }))

    network_rule_set = optional(object({
      default_action = string
      ip_rules = optional(list(object({
        ip_range = string
      })))
      virtual_network_rules = optional(list(object({
        subnet_name = string
      })))
    }))

    georeplications = optional(list(object({
      location                  = string
      zone_redundancy_enabled   = optional(bool)
      regional_endpoint_enabled = optional(bool)
      tags                      = optional(map(string))
    })))

    encryption = optional(object({
      enabled            = optional(bool)
      key_vault_key_id   = optional(string)
      identity_client_id = optional(string)
    }))

    private_endpoints = optional(list(object({
      name                          = string
      location                      = optional(string)
      resource_group_name           = optional(string)
      custom_network_interface_name = optional(string)
      subnet_name                   = string
      member_name                   = optional(string)
      ip_configuration = optional(object({
        private_ip_address = string
      }))
      private_dns_zone_names = optional(list(string))
      tags                   = optional(map(string))
    })))

    acr_push_identity_names = optional(list(string))
    acr_push_principal_ids  = optional(list(string))

    tags = optional(map(string))
  }))
  default = null
}

# Azure Monitor Workspace (Prometheus backend)
variable "monitor_workspaces" {
  type = list(object({
    name                = string
    resource_group_name = string
    location            = string
    tags                = optional(map(string))
  }))
  default = null
}

# Application Insights (workspace-based APM)
variable "application_insights" {
  type = list(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    application_type              = optional(string, "web")
    log_analytics_workspace_name  = optional(string)
    workspace_id                  = optional(string)
    sampling_percentage           = optional(number)
    retention_in_days             = optional(number)
    daily_data_cap_in_gb          = optional(number)
    internet_ingestion_enabled    = optional(bool)
    internet_query_enabled        = optional(bool)
    local_authentication_disabled = optional(bool)
    tags                          = optional(map(string))
  }))
  default = null
}

# Azure Managed Grafana
variable "dashboard_grafanas" {
  type = list(object({
    name                              = string
    resource_group_name               = string
    location                          = string
    sku                               = optional(string)
    zone_redundancy_enabled           = optional(bool)
    api_key_enabled                   = optional(bool)
    deterministic_outbound_ip_enabled = optional(bool)
    public_network_access_enabled     = optional(bool)
    grafana_major_version             = optional(number)
    azure_monitor_workspace_names     = optional(list(string))
    grafana_admin_principal_ids       = optional(list(string))
    tags                              = optional(map(string))
  }))
  default = null
}

# Monitor Metric Alerts
variable "monitor_metric_alerts" {
  type = list(object({
    name                = string
    resource_group_name = string
    description         = optional(string)
    enabled             = optional(bool, true)
    auto_mitigate       = optional(bool, true)
    severity            = optional(number, 3)
    frequency           = optional(string, "PT1M")
    window_size         = optional(string, "PT5M")

    scopes                   = optional(list(string))
    target_resource_module   = optional(string)
    target_resource_name     = optional(string)
    target_resource_type     = optional(string)
    target_resource_location = optional(string)

    criteria = optional(list(object({
      metric_namespace       = optional(string)
      metric_name            = string
      aggregation            = string
      operator               = string
      threshold              = number
      skip_metric_validation = optional(bool)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })))
    })))

    dynamic_criteria = optional(list(object({
      metric_namespace         = optional(string)
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = string
      evaluation_total_count   = optional(number)
      evaluation_failure_count = optional(number)
      ignore_data_before       = optional(string)
      skip_metric_validation   = optional(bool)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })))
    })))

    action = list(object({
      action_group_id    = optional(string)
      action_group_name  = optional(string)
      webhook_properties = optional(map(string))
    }))

    tags = optional(map(string))
  }))
  default = null
}

# Monitor Scheduled Query Rules (Log Alerts v2)
variable "monitor_scheduled_query_rules" {
  type = list(object({
    name                 = string
    resource_group_name  = string
    location             = string
    display_name         = optional(string)
    description          = optional(string)
    enabled              = optional(bool, true)
    severity             = optional(number, 3)
    evaluation_frequency = string
    window_duration      = string

    scopes                = optional(list(string))
    scope_resource_module = optional(string)
    scope_resource_name   = optional(string)

    target_resource_types             = optional(list(string))
    auto_mitigation_enabled           = optional(bool)
    workspace_alerts_storage_enabled  = optional(bool)
    mute_actions_after_alert_duration = optional(string)
    query_time_range_override         = optional(string)
    skip_query_validation             = optional(bool)

    criteria = object({
      query                   = string
      operator                = string
      threshold               = number
      time_aggregation_method = string
      metric_measure_column   = optional(string)
      resource_id_column      = optional(string)
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })))
      failing_periods = optional(object({
        minimum_failing_periods_to_trigger_alert = number
        number_of_evaluation_periods             = number
      }))
    })

    action = optional(object({
      action_group_ids   = optional(list(string))
      action_group_names = optional(list(string))
      custom_properties  = optional(map(string))
    }))

    tags = optional(map(string))
  }))
  default = null
}

# Linux VM Monitoring Agents (AzureMonitorLinuxAgent + Data Collection Rule)
variable "linux_vm_monitoring_agents" {
  type = list(object({
    linux_virtual_machine_name = string
    resource_group_name        = string
    location                   = string
    enabled                    = optional(bool, true)

    log_analytics_workspace_id   = optional(string)
    log_analytics_workspace_name = optional(string)

    dcr_name                      = optional(string)
    sampling_frequency_in_seconds = optional(number)
    counter_specifiers            = optional(list(string))

    collect_syslog        = optional(bool)
    syslog_facility_names = optional(list(string))
    syslog_log_levels     = optional(list(string))

    identity_type               = optional(string)
    user_assigned_identity_name = optional(string)

    tags = optional(map(string))
  }))
  default = null
}
