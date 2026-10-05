# Global parameters
tenant_id = "73929700-4276-4f04-90b2-cabccd0f3c8b"

subscription_id = "e795b910-68e2-484a-92b5-02bd7ca2d517" # subscription id of BPM UAT environment

# Resource Group
resource_groups = [
  {
    name     = "BPM-UAT-RG"
    location = "East Asia"

    tags = {
      Environment = "UAT"
      Owner       = "Business Operations"
      Project     = "BPM"
    }
  }
]

# Virtual Network
virtual_networks = [
  {
    name                = "BPM-UAT-VNET-01"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
    address_space       = ["10.128.58.0/23"]

    subnets = [
      {
        name           = "BPM-UAT-PE-SUBNET-01"
        address_prefix = "10.128.58.64/28"

        # Disabled: Bypass NSG and route table policies for Private Endpoint traffic 
        # This ensures Private Link connectivity is not affected by network policies
        private_endpoint_network_policies = "Disabled"
        network_security_group = {
          name = "BPM-UAT-PE-NSG-01"
        }
        # No route table for Private Endpoint subnet - allows direct Private Link connectivity
        # Route tables can interfere with Private Endpoint traffic to external services like MongoDB Atlas
      },
      # {
      #   name           = "BPM-UAT-JUMP-SUBNET-01"
      #   address_prefix = "10.128.58.48/28"

      #   network_security_group = {
      #     name = "BPM-UAT-JUMP-NSG-01"
      #     rules = [
      #       {
      #         name                       = "AllowSOSRDPInbound"
      #         priority                   = 100
      #         direction                  = "Inbound"
      #         access                     = "Allow"
      #         protocol                   = "Tcp"
      #         source_address_prefix      = "125.215.171.249"
      #         source_port_range          = "*"
      #         destination_address_prefix = "*"
      #         destination_port_range     = "3389"
      #       },
      #       {
      #         name                         = "AllowPrivateEndpointSubnet"
      #         priority                     = 110
      #         direction                    = "Inbound"
      #         access                       = "Allow"
      #         protocol                     = "*"
      #         source_address_prefix        = "10.128.58.64/28"
      #         source_port_range            = "*"
      #         destination_address_prefixes = ["10.128.46.32/28", "10.128.46.48/28", "10.128.46.64/26"]
      #         destination_port_range       = "1433"
      #       },
      #       {
      #         name                       = "AllowDatafactory8080Inbound"
      #         priority                   = 120
      #         direction                  = "Inbound"
      #         access                     = "Allow"
      #         protocol                   = "*"
      #         source_address_prefix      = "DataFactory"
      #         source_port_range          = "*"
      #         destination_address_prefix = "*"
      #         destination_port_range     = "8080"
      #       },
      #       {
      #         name                       = "Allow-Tectura-To-BPM-DEV-JUMP-VM-01-RDP-01"
      #         priority                   = 130
      #         direction                  = "Inbound"
      #         access                       = "Allow"
      #         protocol                   = "Tcp"
      #         source_address_prefixes    = ["103.244.159.242", "103.244.159.244", "27.38.209.69", "116.49.244.41", "120.226.116.208", "220.203.227.136", "103.242.168.245", "163.142.49.74", "20.239.199.69", "110.235.24.71"]
      #         source_port_range          = "*"
      #         destination_address_prefix = "10.128.58.52"
      #         destination_port_range     = "3389"
      #       },
      #       {
      #         name                       = "AllowCidrBlockCustom3389Inbound"
      #         priority                   = 140
      #         direction                  = "Inbound"
      #         access                     = "Allow"
      #         protocol                   = "*"
      #         source_address_prefixes    = ["104.208.103.112"]
      #         source_port_range          = "*"
      #         destination_address_prefix = "*"
      #         destination_port_range     = "3389"
      #       }
      #     ]
      #   }
      #   route_table = {
      #     name                          = "BPM-UAT-JUMP-RT-01"
      #     bgp_route_propagation_enabled = false
      #     routes = [
      #       {
      #         name                   = "Route-CCG-WVD-SUBNET"
      #         address_prefix         = "192.168.41.0/24"
      #         next_hop_type          = "VirtualAppliance"
      #         next_hop_in_ip_address = "10.143.2.4"
      #       },
      #       {
      #         name                   = "Route-BPM-PRD-SUBNET"
      #         address_prefix         = "10.128.50.0/23"
      #         next_hop_type          = "VirtualAppliance"
      #         next_hop_in_ip_address = "10.143.2.4"
      #       }
      #     ]
      #   }
      # },
      {
        name           = "BPM-UAT-AGW-SUBNET-01"
        address_prefix = "10.128.58.0/27"

        network_security_group = {
          name = "BPM-UAT-AGW-NSG-01"

          rules = [
            # Required by Azure for AGW v2: allow user traffic on HTTP and HTTPS
            # Without these, DenyAllInBound blocks all internet traffic before AGW processes it
            # Ref: https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups
            {
              name                       = "Allow-Internet-To-AGW-HTTP-80"
              priority                   = 100
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_address_prefix      = "Internet"
              source_port_range          = "*"
              destination_address_prefix = "*"
              destination_port_range     = "80"
            },
            {
              name                       = "Allow-Internet-To-AGW-HTTPS-443"
              priority                   = 110
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_address_prefix      = "Internet"
              source_port_range          = "*"
              destination_address_prefix = "*"
              destination_port_range     = "443"
            },
            # Required by Azure for AGW v2: allow internal health probe traffic from GatewayManager
            {
              name                       = "Allow-GatewayManager-To-Any-TCP-65200-65535-01"
              priority                   = 500
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_address_prefix      = "GatewayManager"
              source_port_range          = "*"
              destination_address_prefix = "*"
              destination_port_ranges    = ["65200-65535"]
            }
          ]
        }
        route_table = {
          name                          = "BPM-UAT-AGW-RT-01"
          bgp_route_propagation_enabled = false
          routes                        = []
        }
      },
      {
        name           = "BPM-UAT-ACR-SUBNET-01"
        address_prefix = "10.128.58.96/28"

        network_security_group = {
          name = "BPM-UAT-ACR-NSG-01"
        }
        route_table = {
          name                          = "BPM-UAT-ACR-RT-01"
          bgp_route_propagation_enabled = false
          routes = [
            {
              name                   = "Default-route"
              address_prefix         = "0.0.0.0/0"
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.143.2.4"
            }
          ]
        }
      },
      {
        name           = "BPM-UAT-VM-SUBNET-01"
        address_prefix = "10.128.58.128/26"

        network_security_group = {
          name = "BPM-UAT-VM-NSG-01"
        }
        route_table = {
          name                          = "BPM-UAT-VM-RT-01"
          bgp_route_propagation_enabled = false
          routes = [
            {
              name           = "PE-Subnet-Local"
              address_prefix = "10.128.58.64/28"
              next_hop_type  = "VnetLocal"
            },
            {
              name                   = "Default-route"
              address_prefix         = "0.0.0.0/0"
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.143.2.4"
            }
          ]
        }
      },
      {
        name           = "BPM-UAT-AKS-SUBNET-01"
        address_prefix = "10.128.59.0/24"

        network_security_group = {
          name = "BPM-UAT-AKS-NSG-01"
        }
        route_table = {
          name                          = "BPM-UAT-AKS-RT-01"
          bgp_route_propagation_enabled = false
          routes = [
            {
              name           = "PE-Subnet-Local"
              address_prefix = "10.128.58.64/28"
              next_hop_type  = "VnetLocal"
            },
            {
              name                   = "Default-route"
              address_prefix         = "0.0.0.0/0"
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.143.2.4"
            }
          ]
        }
      }
    ]
  }
]

# Storage Account
storage_accounts = [
  {
    name                             = "bpmuatstgacc01"
    location                         = "East Asia"
    resource_group_name              = "BPM-UAT-RG"
    account_kind                     = "StorageV2"
    account_tier                     = "Standard"
    account_replication_type         = "ZRS"
    cross_tenant_replication_enabled = false
    https_traffic_only_enabled       = true

    sas_policy = {
      expiration_period = "00.01:00:00"
      expiration_action = "Log"
    }

    blob_properties = {
      change_feed_enabled           = true
      change_feed_retention_in_days = 35
      versioning_enabled            = true

      delete_retention_policy = {
        days = 365
      }
      container_delete_retention_policy = {
        days = 30
      }
      restore_policy = {
        days = 30
      }
    }

    share_properties = {
      retention_policy = {
        days = 30
      }
    }

    min_tls_version = "TLS1_2"

    public_network_access_enabled     = false
    infrastructure_encryption_enabled = true

    network_rules = {
      default_action = "Deny"
    }

    private_endpoints = [
      {
        name                          = "BPM-UAT-STGACC-PE-01"
        custom_network_interface_name = "BPM-UAT-STGACC-PE-01-nic"

        subresource_name = "blob"

        ip_configuration = {
          private_ip_address = "10.128.58.71"
        }

        subnet_name = "BPM-UAT-PE-SUBNET-01"

        private_dns_zone_names = [
          "privatelink.blob.core.windows.net"
        ]
      }
    ]

    monitor_diagnostic_settings = [
      {
        name                         = "BPM-UAT-DS-STGACC-BLOB-01"
        sub_resource_name            = "blobServices"
        log_analytics_workspace_name = "BPM-UAT-LOG-01"
        enabled_log = [
          { category = "StorageRead" },
          { category = "StorageWrite" },
          { category = "StorageDelete" }
        ]
        metric = [
          { category = "Transaction", enabled = true }
        ]
      },
      {
        name                         = "BPM-UAT-DS-STGACC-QUEUE-01"
        sub_resource_name            = "queueServices"
        log_analytics_workspace_name = "BPM-UAT-LOG-01"
        enabled_log = [
          { category = "StorageRead" },
          { category = "StorageWrite" },
          { category = "StorageDelete" }
        ]
        metric = [
          { category = "Transaction", enabled = true }
        ]
      },
      {
        name                         = "BPM-UAT-DS-STGACC-TABLE-01"
        sub_resource_name            = "tableServices"
        log_analytics_workspace_name = "BPM-UAT-LOG-01"
        enabled_log = [
          { category = "StorageRead" },
          { category = "StorageWrite" },
          { category = "StorageDelete" }
        ]
        metric = [
          { category = "Transaction", enabled = true }
        ]
      },
      {
        name                         = "BPM-UAT-DS-STGACC-FILE-01"
        sub_resource_name            = "fileServices"
        log_analytics_workspace_name = "BPM-UAT-LOG-01"
        enabled_log = [
          { category = "StorageRead" },
          { category = "StorageWrite" },
          { category = "StorageDelete" }
        ]
        metric = [
          { category = "Transaction", enabled = true }
        ]
      }
    ]
  }
]

# Private DNS Zone
private_dns_zones = [
  {
    name                = "privatelink.mysql.database.azure.com"
    resource_group_name = "BPM-UAT-RG"

    virtual_network_links = [
      {
        name                 = "BPM-UAT-VNET-01-LINK"
        virtual_network_name = "BPM-UAT-VNET-01"
        registration_enabled = false
      }
    ]
  },
  {
    name                = "privatelink.vaultcore.azure.net"
    resource_group_name = "BPM-UAT-RG"

    virtual_network_links = [
      {
        name                 = "BPM-UAT-VNET-01-LINK"
        virtual_network_name = "BPM-UAT-VNET-01"
        registration_enabled = false
      }
    ]
  },
  {
    name                = "privatelink.blob.core.windows.net"
    resource_group_name = "BPM-UAT-RG"

    virtual_network_links = [
      {
        name                 = "BPM-UAT-VNET-01-LINK"
        virtual_network_name = "BPM-UAT-VNET-01"
        registration_enabled = false
      }
    ]
  },
  {
    name                = "privatelink.azurecr.io"
    resource_group_name = "BPM-UAT-RG"

    virtual_network_links = [
      {
        name                 = "BPM-UAT-VNET-01-LINK"
        virtual_network_name = "BPM-UAT-VNET-01"
        registration_enabled = false
      }
    ]
  },
  {
    name                = "mongodb.net"
    resource_group_name = "BPM-UAT-RG"

    virtual_network_links = [
      {
        name                 = "BPM-UAT-VNET-01-LINK"
        virtual_network_name = "BPM-UAT-VNET-01"
        registration_enabled = false
      }
    ]

    # MongoDB Atlas Private Link A records
    # PE IP: 10.128.58.73 (from BPM-UAT-MONGO-PE-01)
    # Private Endpoint hostname: pl-0-eastasia-azure.oxeheu.mongodb.net (ports 1024-1026)
    # Connection string: mongodb://pl-0-eastasia-azure.oxeheu.mongodb.net:1024,1025,1026
    a_records = [
      {
        name    = "pl-0-eastasia-azure.oxeheu"
        ttl     = 300
        records = ["10.128.58.73"]
      }
    ]
  }
]

# Linux Virtual Machines
linux_virtual_machines = [
  {
    name                = "BPM-UAT-MIDDLEWARE-VM-01"
    resource_group_name = "BPM-UAT-RG"
    location            = "East Asia"
    size                = "Standard_D8s_v5"
    zone                = 2
    computer_name       = "BPM-MIDDLEWARE-UAT"

    disable_password_authentication = false
    virtual_network_name            = "BPM-UAT-VNET-01"

    network_interfaces = [
      {
        name                = "BPM-UAT-MIDDLEWARE-VM-01-NIC-01"
        location            = "East Asia"
        resource_group_name = "BPM-UAT-RG"
        ip_configurations = [
          {
            name                          = "internal"
            subnet_name                   = "BPM-UAT-VM-SUBNET-01"
            private_ip_address_allocation = "Static"
            private_ip_address            = "10.128.58.132"
            primary                       = true
          }
        ]
      }
    ]

    os_disk = {
      name                 = "BPM-UAT-MIDDLEWARE-VM-01-OS-DISK"
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 256
    }

    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }

    boot_diagnostics = {
      storage_account_uri = null
    }

    identity = {
      type = "SystemAssigned, UserAssigned"
      identity_ids = [
        "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/BPM-UAT-UAI-AKS-USER",
        "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/BPM-UAT-UAI-AKS-ADM"
      ]
    }

    data_disks = [
      {
        name                 = "BPM-UAT-MIDDLEWARE-VM-01-DATA-DISK-01"
        storage_account_type = "Premium_LRS"
        create_option        = "Empty"
        disk_size_gb         = 256
        lun                  = 0
        caching              = "ReadWrite"
      }
    ]

    backup_protected_vm = {
      recovery_vault_name = "BPM-UAT-RSV-01"
      backup_policy_name  = "BPMUATRSVPOL01"
    }
  }
]

# Linux VM Admin Credentials
# Note: These should be set in Terraform Cloud workspace variables as sensitive values
# linux_virtual_machines_admin_username = "azureuser"
# linux_virtual_machines_admin_password = "P@ssw0rd123!"

# Key Vault
key_vaults = [
  {
    name = "CCG-BPM-UAT-KV-01"

    resource_group_name = "BPM-UAT-RG"
    location            = "East Asia"
    sku_name            = "standard"

    enabled_for_deployment          = false
    enabled_for_disk_encryption     = false
    enabled_for_template_deployment = false
    enable_rbac_authorization       = true
    purge_protection_enabled        = true
    public_network_access_enabled   = false
    soft_delete_retention_days      = 90

    network_acls = {
      bypass         = "AzureServices"
      default_action = "Deny"
    }

    secrets_user_identity_names    = ["BPM-UAT-UAI-AGW"]
    secrets_user_aks_kubelet_names = ["BPM-UAT-AKS-01"]

    keys = [
      {
        name     = "BPM-UAT-KEY-SQLDB"
        key_type = "RSA"
        key_size = 2048

        key_opts = [
          "decrypt",
          "encrypt",
          "sign",
          "unwrapKey",
          "verify",
          "wrapKey"
        ]
      }
    ]

    # Values live in the sensitive var.key_vault_secret_values map in Terraform
    # Cloud (keyed by name). To rotate yearly, push expiration_date ~1 year out
    # (and update the value in TFC), then apply. Dates below are UTC.
    secrets = [
      { name = "AppInsight-ConnectionString", content_type = "text/plain", expiration_date = "2028-07-22T00:00:00Z" },
      { name = "BPM-integration-GraphAPI-Secret", content_type = "text/plain", expiration_date = "2027-03-16T00:00:00Z" },
      { name = "GemBox-License", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "Nocoly-API-Key", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "Nocoly-API-Sign", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "Nocoly-Staff-Master-API-Key", content_type = "text/plain", expiration_date = "2028-07-03T00:00:00Z" },
      { name = "Nocoly-Staff-Master-API-Sign", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "Org-App-Key", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "Org-App-Secret", content_type = "text/plain", expiration_date = "2028-06-30T00:00:00Z" },
      { name = "Org-ID", content_type = "text/plain", expiration_date = "2028-07-21T00:00:00Z" },
      { name = "SharePoint-Client-ID", content_type = "text/plain", expiration_date = "2028-06-16T00:00:00Z" },
      { name = "SharePoint-Client-Secret", content_type = "text/plain", expiration_date = "2028-07-13T00:00:00Z" },
      { name = "SharePoint-Tenant-ID", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "SMTP-Host", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "SMTP-Password", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "SMTP-User-Name", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "SQL-connection-string-wk-account", content_type = "text/plain", expiration_date = "2028-06-26T00:00:00Z" },
      { name = "X-API-Key", content_type = "text/plain", expiration_date = "2028-07-21T00:00:00Z" },
    ]

    private_endpoints = [
      {
        name                          = "BPM-UAT-KV-PE-01"
        custom_network_interface_name = "BPM-UAT-KV-PE-01-nic"

        subresource_name = "vault"
        member_name      = "default"

        ip_configuration = {
          private_ip_address = "10.128.58.69"
        }

        subnet_name = "BPM-UAT-PE-SUBNET-01"

        private_dns_zone_names = [
          "privatelink.vaultcore.azure.net"
        ]
      }
    ]
  }
]

# Azure Container Registry
container_registries = [
  {
    name                          = "ccgbpmuatacr01"
    resource_group_name           = "BPM-UAT-RG"
    location                      = "East Asia"
    sku                           = "Premium"
    admin_enabled                 = false
    public_network_access_enabled = true
    zone_redundancy_enabled       = false
    network_rule_bypass_option    = "AzureServices"

    network_rule_set = {
      default_action = "Deny"
      ip_rules = [
        {
          ip_range = "47.76.41.170/32" # Alicloud Jenkins
        }
      ]
    }

    private_endpoints = [
      {
        name                          = "BPM-UAT-ACR-PE-01"
        custom_network_interface_name = "BPM-UAT-ACR-PE-01-nic"
        subnet_name                   = "BPM-UAT-PE-SUBNET-01"

        private_dns_zone_names = [
          "privatelink.azurecr.io"
        ]
      }
    ]

    # Grant AcrPush to middleware VM identity for image deployment
    acr_push_identity_names = ["BPM-UAT-UAI-AKS-ADM"]
    acr_push_principal_ids  = ["33559433-9e5b-478c-a6c8-a27984809ee2"] # Jenkins BPM App Deployment UAT
  }
]

# Azure Kubernetes Service
kubernetes_clusters = [
  {
    name                = "BPM-UAT-AKS-01"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
    dns_prefix          = "bpm-uat-aks"
    # kubernetes_version              = "1.34.0"  # Patch auto-managed; uncomment only for minor version upgrades
    sku_tier                                  = "Free"
    automatic_upgrade_channel                 = "patch"
    node_os_upgrade_channel                   = "SecurityPatch"
    private_cluster_enabled                   = true
    role_based_access_control_enabled         = true
    attach_acr_names                          = ["ccgbpmuatacr01"]
    allow_identity_access_user                = ["BPM-UAT-UAI-AKS-USER"]
    allow_identity_access_admin               = ["BPM-UAT-UAI-AKS-ADM"]
    allow_identity_access_contributor         = ["BPM-UAT-UAI-AKS-ADM"]
    allow_principal_access_admin              = ["33559433-9e5b-478c-a6c8-a27984809ee2"] # Jenkins BPM App Deployment UAT
    allow_identity_subnet_network_contributor = ["BPM-UAT-UAI-AKS-ADM"]

    # Grants Network Contributor on BPM-UAT-AKS-SUBNET-01 to the AKS cluster's
    # SystemAssigned identity (principalId: 37418faf-ee55-40ac-843d-4f499c5e9a7f).
    # Resolves: LinkedAuthorizationFailed - subnets/join/action when AKS
    # provisions an internal LoadBalancer service.
    grant_subnet_network_contributor = true

    default_node_pool = {
      name                         = "agentpool"
      vm_size                      = "Standard_D4as_v5"
      node_count                   = 1
      enable_auto_scaling          = false
      os_disk_size_gb              = 48
      os_disk_type                 = "Managed"
      subnet_name                  = "BPM-UAT-AKS-SUBNET-01"
      max_pods                     = 30
      temporary_name_for_rotation  = "tmppool"
      only_critical_addons_enabled = true

      upgrade_settings = {
        drain_timeout_in_minutes      = 0
        max_surge                     = "10%"
        node_soak_duration_in_minutes = 0
      }
    }

    identity = {
      type = "SystemAssigned"
    }

    network_profile = {
      network_plugin    = "azure"
      network_policy    = "azure"
      dns_service_ip    = "10.129.0.10"
      service_cidr      = "10.129.0.0/16"
      load_balancer_sku = "standard"
      outbound_type     = "userDefinedRouting"
    }

    azure_active_directory_role_based_access_control = {
      azure_rbac_enabled = true
    }

    oms_agent = {
      log_analytics_workspace_id      = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.OperationalInsights/workspaces/BPM-UAT-LOG-01"
      msi_auth_for_monitoring_enabled = true
    }

    enable_container_insights   = true
    container_insights_dcr_name = "BPM-UAT-DCR-AKS-01"
    container_insights_interval = "5m"

    monitor_metrics = {
      annotations_allowed = null
      labels_allowed      = null
    }

    enable_prometheus      = true
    monitor_workspace_name = "BPM-UAT-MONWS-01"
    prometheus_dcr_name    = "BPM-UAT-DCR-PROM-01"
    prometheus_dce_name    = "BPM-UAT-DCE-PROM-01"

    service_mesh_profile = {
      mode                             = "Istio"
      revisions                        = ["asm-1-26"]
      internal_ingress_gateway_enabled = false
      external_ingress_gateway_enabled = false
    }

    # Sun 03:00-07:00 HKT for cluster + node-OS patches (min duration 4h).
    maintenance_window_auto_upgrade = {
      frequency   = "Weekly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      start_time  = "03:00"
      utc_offset  = "+08:00"
    }

    maintenance_window_node_os = {
      frequency   = "Weekly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      start_time  = "03:00"
      utc_offset  = "+08:00"
    }

    additional_node_pools = [
      {
        name                        = "happool"
        vm_size                     = "Standard_D16as_v5"
        node_count                  = 2
        os_disk_size_gb             = 128
        os_disk_type                = "Managed"
        subnet_name                 = "BPM-UAT-AKS-SUBNET-01"
        max_pods                    = 95
        temporary_name_for_rotation = "tmphap"

        upgrade_settings = {
          drain_timeout_in_minutes      = 0
          max_surge                     = "10%"
          node_soak_duration_in_minutes = 0
        }
      },
      {
        name                        = "flinkpool"
        vm_size                     = "Standard_D8as_v5"
        node_count                  = 1
        os_disk_size_gb             = 128
        os_disk_type                = "Managed"
        subnet_name                 = "BPM-UAT-AKS-SUBNET-01"
        max_pods                    = 20
        temporary_name_for_rotation = "tmpflink"
        node_taints                 = ["hap=flink:NoSchedule"]
        node_labels                 = { hap = "flink" }

        upgrade_settings = {
          drain_timeout_in_minutes      = 0
          max_surge                     = "10%"
          node_soak_duration_in_minutes = 0
        }
      }
    ]
  }
]

# Web Application Firewall Policy
web_application_firewall_policies = [
  {
    name                = "BPM-UAT-AGWWFP-01"
    resource_group_name = "BPM-UAT-RG"
    location            = "East Asia"

    policy_settings = {
      enabled                          = true
      mode                             = "Prevention"
      request_body_check               = false
      file_upload_limit_in_mb          = 100
      max_request_body_size_in_kb      = 768
      request_body_inspect_limit_in_kb = 768
      request_body_enforcement         = false
    }

    managed_rules = {
      exclusions = [
        {
          # jdbcTypeId field name triggers SQL injection detection rules
          match_variable          = "RequestArgNames"
          selector_match_operator = "Contains"
          selector                = "jdbcTypeId"
        },
        {
          # dataSource field name triggers SQL/data exfiltration rules
          match_variable          = "RequestArgNames"
          selector_match_operator = "Contains"
          selector                = "dataSource"
        },
        {
          # precision with large integer (2147483647) triggers SQL injection rules
          match_variable          = "RequestArgNames"
          selector_match_operator = "Contains"
          selector                = "precision"
        },
        {
          # isdecrypt keyword triggers security rules
          match_variable          = "RequestArgNames"
          selector_match_operator = "Contains"
          selector                = "isdecrypt"
        },
        {
          # Custom authorization header format (md_pss_id) triggers header anomaly rules
          match_variable          = "RequestHeaderNames"
          selector_match_operator = "Contains"
          selector                = "authorization"
        },
        {
          # HAP-Sign custom header triggers header anomaly rules
          match_variable          = "RequestHeaderNames"
          selector_match_operator = "Contains"
          selector                = "hap-sign"
        },
        {
          # OIDC SSO callback: code/state tokens trigger SQLi anomaly rules
          match_variable          = "RequestArgNames"
          selector_match_operator = "Contains"
          selector                = "code"
          excluded_rule_sets = [
            {
              type    = "Microsoft_DefaultRuleSet"
              version = "2.1"
              rule_groups = [
                { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300"] },
                { rule_group_name = "SQLI", excluded_rules = ["942430", "942440"] }
              ]
            }
          ]
        }
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/wwwapi/Worksheet/SaveWorksheetControls"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/wwwapi/Worksheet/UpdateWorksheetRow"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/api/workflow/process/startProcess"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/wwwapi/Worksheet/GetRowDetail"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/wwwapi/Worksheet/SaveWorksheetView"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/report/custom/savePage"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #},
        #{
        #  # For nocoly api call exclusion
        #  match_variable          = "RequestArgNames"
        #  selector_match_operator = "Contains"
        #  selector                = "/report/report/getData"
        #  excluded_rule_sets = [
        #    {
        #      type    = "Microsoft_DefaultRuleSet"
        #      version = "2.1"
        #      rule_groups = [
        #        { rule_group_name = "PROTOCOL-ENFORCEMENT", excluded_rules = ["920320", "920300","920230"] },
        #        { rule_group_name = "SQLI", excluded_rules = ["942430", "942440", "942200", "942260", "942330", "942340", "942370"] },
        #        { rule_group_name = "XSS", excluded_rules = ["941330", "941340" ] }
        #      ]
        #    }
        #  ]
        #}
      ]

      managed_rule_sets = [
        {
          type    = "Microsoft_DefaultRuleSet"
          version = "2.1"
        },
        {
          type    = "Microsoft_BotManagerRuleSet"
          version = "1.1"
        },
        # Assigned in Azure, but azurerm 4.62.0 rejects this type. Once supported,
        # uncomment and drop ignore_changes in the module.
        # https://github.com/hashicorp/terraform-provider-azurerm/pull/32708
        # {
        #   type    = "Microsoft_HTTPDDoSRuleSet"
        #   version = "1.0"
        #   rule_group_overrides = [
        #     {
        #       rule_group_name = "ExcessiveRequests"
        #       rules = [
        #         { id = "500100", enabled = true, action = "Log" },
        #         { id = "500110", enabled = true, action = "Log" }
        #       ]
        #     }
        #   ]
        # }
      ]
    }

    custom_rules = [
      {
        name      = "AllowSOS"
        action    = "Allow"
        priority  = 11
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["125.215.171.249/32"]
          }
        ]
      },
      {
        name      = "AllowCCG01"
        action    = "Allow"
        priority  = 12
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["165.85.138.202/32", "165.85.138.203/32", "137.83.238.59/32", "137.83.238.183/32", "165.85.177.1/32", "165.85.47.124/32", "165.85.47.77/32"]
          }
        ]
      },
      {
        name      = "AllowCCG02"
        action    = "Allow"
        priority  = 13
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["165.85.154.159/32", "165.85.154.160/32", "134.238.246.225/32", "134.238.38.218/32"]
          }
        ]
      },
      {
        name      = "AllowCCGHQWifiIPs"
        action    = "Allow"
        priority  = 14
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["123.1.251.200/32", "101.78.128.100/32", "113.28.108.1/32", "113.28.108.249/32"]
          }
        ]
      },
      {
        name      = "AllowCCGBYODWIFIIPs"
        action    = "Allow"
        priority  = 15
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["113.28.108.246/32", "123.1.251.246/32", "113.28.108.122/32", "101.78.128.98/32"]
          }
        ]
      },
      {
        name      = "AllowSASEIPs"
        action    = "Allow"
        priority  = 16
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["165.85.138.202/32", "165.85.138.203/32", "137.83.238.59/32", "137.83.238.183/32", "165.85.177.1/32", "165.85.47.124/32", "165.85.47.77/32", "165.85.154.159/32", "165.85.154.160/32", "134.238.246.225/32", "134.238.38.218/32"]
          }
        ]
      },
      {
        name      = "AllowFortiSASEIPs"
        action    = "Allow"
        priority  = 17
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["23.249.58.35/32","209.40.123.81/32","95.45.44.19/32","66.35.31.236/32"]
          }
        ]
      },
      {
        name      = "AllowPRTGIPs"
        action    = "Allow"
        priority  = 18
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["123.1.251.204/32", "101.78.128.104/32", "113.28.108.4/32", "113.28.108.252/32"]
          }
        ]
      },
      {
        name      = "AllowCatomind"
        action    = "Allow"
        priority  = 19
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values = [
              "58.177.202.90/32",  # Hong Kong Office
              "183.11.236.203/32", # Shenzhen Office
              "210.209.94.65/32",  # ZhuHai Office
              "118.163.227.76/32", # Taiwan Office
              "14.136.11.98/32",   # Hong Kong office 17f
            ]
          }
        ]
      },
      {
        name      = "AllowNocoly"
        action    = "Allow"
        priority  = 20
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["58.33.90.218/32"]
          }
        ]
      },
      {
        name      = "AllowDataFactory"
        action    = "Allow"
        priority  = 21
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["20.187.84.181/32"] #Hub Firewall Public IP
          }
        ]
      },
      {
        name      = "AllowCyberark"
        action    = "Allow"
        priority  = 22
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = false
            match_values       = ["113.28.108.240/32", "123.1.251.240/32", "101.78.128.122/32", "113.28.108.119/32"] #CyberArk Outgoing IPs (IP1-IP4)
          }
        ]
      },
      {
        name      = "AllowURIChatbot"
        action    = "Allow"
        priority  = 23
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RequestUri" }]
            operator           = "Contains"
            negation_condition = false
            match_values       = ["/file/mdpic/ChatBotFile"]
          }
        ]
      },
      {
        name      = "AllowWVDwithManagedRules"
        enabled   = "true"
        action    = "Block"
        priority  = 24
        rule_type = "MatchRule"
        match_conditions = [
          {
            match_variables    = [{ variable_name = "RemoteAddr" }]
            operator           = "IPMatch"
            negation_condition = true
            match_values       = ["104.208.103.112/32", "104.208.103.132/32", "20.24.109.169/32"] #WVD IP with managed rules
          }
        ]
      }
      # {
      #   name      = "DenyAny"
      #   action    = "Block"
      #   priority  = 90
      #   rule_type = "MatchRule"
      #   match_conditions = [
      #     {
      #       match_variables    = [{ variable_name = "RemoteAddr" }]
      #       operator           = "IPMatch"
      #       negation_condition = false
      #       match_values       = ["0.0.0.0/0", "::/0"]
      #     }
      #   ]
      # }
    ]
  }
]

# Application Gateway
application_gateways = [
  {
    name                 = "BPM-UAT-AGW-01"
    resource_group_name  = "BPM-UAT-RG"
    location             = "East Asia"
    zones                = ["1", "2", "3"]
    enable_http2         = true
    firewall_policy_name = "BPM-UAT-AGWWFP-01"

    sku = {
      name = "WAF_v2"
      tier = "WAF_v2"
    }

    autoscale_configuration = {
      min_capacity = 1
      max_capacity = 2
    }

    gateway_ip_configurations = [
      {
        name        = "BPM-UAT-AGW-01-ip-config"
        subnet_name = "BPM-UAT-AGW-SUBNET-01"
      }
    ]

    frontend_ip_configurations = [
      {
        name = "BPM-UAT-AGW-01-frontend-public"
        public_ip = {
          name              = "BPM-UAT-PIP-01"
          allocation_method = "Static"
          sku               = "Standard"
          zones             = ["1", "2", "3"]
        }
      }
    ]

    frontend_ports = [
      {
        name = "http-port-80"
        port = 80
      },
      {
        name = "https-port-443"
        port = 443
      }
    ]

    ssl_certificates = [
      {
        name                = "chinachemgroup-2627"
        key_vault_secret_id = "https://ccg-bpm-uat-kv-01.vault.azure.net/secrets/chinachemgroup-2627"
      }
    ]

    backend_address_pools = [
      {
        name         = "BPM-UAT-AGW-01-backend-pool"
        ip_addresses = ["10.128.58.132"]
      }
    ]

    all_backend_http_settings = [
      {
        name                  = "BPM-UAT-AGW-01-http-settings"
        cookie_based_affinity = "Disabled"
        port                  = "80"
        protocol              = "Http"
        request_timeout       = 60
      }
    ]

    http_listeners = [
      {
        name                           = "BPM-UAT-AGW-01-http-listener"
        frontend_ip_configuration_name = "BPM-UAT-AGW-01-frontend-public"
        frontend_port_name             = "http-port-80"
        protocol                       = "Http"
      },
      {
        name                           = "BPM-UAT-AGW-01-https-listener"
        frontend_ip_configuration_name = "BPM-UAT-AGW-01-frontend-public"
        frontend_port_name             = "https-port-443"
        protocol                       = "Https"
        ssl_certificate_name           = "chinachemgroup-2627"
        host_names                     = ["bpm-uat.chinachemgroup.com"]
      }
    ]

    redirect_configurations = [
      {
        name                 = "BPM-UAT-AGW-01-http-to-https"
        redirect_type        = "Permanent"
        target_listener_name = "BPM-UAT-AGW-01-https-listener"
        include_path         = true
        include_query_string = true
      }
    ]

    request_routing_rules = [
      {
        name                        = "BPM-UAT-AGW-01-routing-rule"
        rule_type                   = "Basic"
        http_listener_name          = "BPM-UAT-AGW-01-http-listener"
        redirect_configuration_name = "BPM-UAT-AGW-01-http-to-https"
        priority                    = 100
      },
      {
        name                       = "BPM-UAT-AGW-01-https-routing-rule"
        rule_type                  = "Basic"
        http_listener_name         = "BPM-UAT-AGW-01-https-listener"
        backend_address_pool_name  = "BPM-UAT-AGW-01-backend-pool"
        backend_http_settings_name = "BPM-UAT-AGW-01-http-settings"
        priority                   = 110
      }
    ]

    identity = {
      type           = "UserAssigned"
      identity_names = ["BPM-UAT-UAI-AGW"]
    }

    allow_identity_network_contributor = ["BPM-UAT-UAI-AKS-ADM"]
  }
]

# Managed Identity
user_assigned_identities = [
  {
    name                = "BPM-UAT-UAI-AGW"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
  },
  {
    name                = "BPM-UAT-UAI-AKS-USER"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
    grant_reader_role   = true
  },
  {
    name                = "BPM-UAT-UAI-AKS-ADM"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
    grant_reader_role   = true
  }
]

# SQL Server
mssql_server_monitor_storage_subscription_id = "6c5d8f25-9e48-4abb-a1d8-007ea18b9ee0"

# MySQL Flexible Server
mysql_flexible_servers = [
  {
    name                         = "bpm-uat-mysql"
    resource_group_name          = "BPM-UAT-RG"
    location                     = "East Asia"
    version                      = "8.4"
    sku_name                     = "GP_Standard_D2ds_v4"
    backup_retention_days        = 35
    geo_redundant_backup_enabled = false
    public_network_access        = "Disabled"

    # Sun 03:00 HKT = Sat 19:00 UTC (Azure MySQL maintenance window is UTC).
    maintenance_window = {
      day_of_week  = 6
      start_hour   = 19
      start_minute = 0
    }

    storage = {
      size_gb           = 20
      auto_grow_enabled = true
      iops              = 360
    }

    databases = [
      {
        name                = "bpm_uat_db"
        resource_group_name = "BPM-UAT-RG"
        charset             = "utf8mb4"
        collation           = "utf8mb4_unicode_ci"
      }
    ]

    firewall_rules = []

    private_endpoints = [
      {
        name                          = "BPM-UAT-SQL-PE-01"
        custom_network_interface_name = "BPM-UAT-SQL-PE-01-nic"
        subnet_name                   = "BPM-UAT-PE-SUBNET-01"
        member_name                   = "mysqlServer"

        ip_configuration = {
          private_ip_address = "10.128.58.70"
        }

        private_dns_zone_names = [
          "privatelink.mysql.database.azure.com"
        ]
      }
    ]
  }
]

# Recovery Services Vault
recovery_services_vaults = [
  {
    name                = "BPM-UAT-RSV-01"
    location            = "East Asia"
    resource_group_name = "BPM-UAT-RG"
    sku                 = "Standard"
    soft_delete_enabled = false

    backup_policy_vm = [
      {
        name                = "BPM-UAT-PSV-01-POL-VM-01"
        resource_group_name = "BPM-UAT-RG"
        policy_type         = "V1"
        timezone            = "China Standard Time"
        backup = {
          frequency = "Daily"
          time      = "01:00"
        }
        retention_daily = {
          count = 7
        }
        retention_weekly = {
          count    = 4
          weekdays = ["Sunday"]
        }
        retention_monthly = {
          count    = 12
          weekdays = ["Sunday"]
          weeks    = ["First"]
        }
      },
      {
        name                = "BPMUATRSVPOL01"
        resource_group_name = "BPM-UAT-RG"
        policy_type         = "V1"
        timezone            = "China Standard Time"
        backup = {
          frequency = "Daily"
          time      = "01:00"
        }
        retention_daily = {
          count = 7
        }
      }
    ]
  }
]

# Monitor Activity Log Alert
monitor_activity_log_alerts = [
  {
    name                = "BPM-UAT-MONALA-01"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Sql/servers/firewallRules/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-02"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Sql/servers/firewallRules/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-03"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-04"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-05"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.ClassicNetwork/networkSecurityGroups/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-06"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.ClassicNetwork/networkSecurityGroups/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-07"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-08"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-09"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.ClassicNetwork/networkSecurityGroups/securityRules/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-10"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.ClassicNetwork/networkSecurityGroups/securityRules/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-11"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Security/securitySolutions/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-12"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Security/securitySolutions/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-13"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/publicIPAddresses/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-14"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Network/publicIPAddresses/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-15"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/policyAssignments/write"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  },
  {
    name                = "BPM-UAT-MONALA-16"
    location            = "Global"
    resource_group_name = "BPM-UAT-RG"
    scopes              = ["/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourcegroups/BPM-UAT-RG"]
    criteria = {
      category       = "Administrative"
      operation_name = "Microsoft.Authorization/policyAssignments/delete"
    }
    action = [
      {
        action_group_name = "BPM-UAT-MONAG-01"
      }
    ]
    enabled = true
  }
]

# Action Group
action_groups = [
  {
    name                = "BPM-UAT-MONAG-01"
    resource_group_name = "BPM-UAT-RG"
    short_name          = "BPM-AG-01"
    location            = "global"
    enabled             = true
    email_receivers = [
      {
        name                    = "Notify misdept"
        email_address           = "misdept@chinachemgroup.com"
        use_common_alert_schema = false
      },
      {
        name                    = "Notify Catomind Support Team"
        email_address           = "tom.leung@catomind.com"
        use_common_alert_schema = false
      },
      {
        name                    = "Notify Catomind Support Team1"
        email_address           = "sunny.chan@catomind.com"
        use_common_alert_schema = false
      }
    ]
  },
  {
    name                = "BPM-UAT-MONAG-02"
    resource_group_name = "BPM-UAT-RG"
    short_name          = "BPM-AG-02"
    location            = "global"
    enabled             = true
    email_receivers = [
      {
        name                    = "Notify Catomind Helpdesk"
        email_address           = "tom.leung@catomind.com" #"helpdesk@catomind.com"
        use_common_alert_schema = true
      }
    ]
  }
]

# Security Center Contact
security_center_contacts = [
  {
    name                = "contact"
    email               = "its_security@chinachemgroup.com"
    alert_notifications = true
    alerts_to_admins    = true
  }
]

# Monitor Diagnostic Setting
monitor_diagnostic_settings = [
  {
    name               = "BPM-UAT-DS-ACTLOG-01"
    target_resource_id = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517"

    storage_account_id = "/subscriptions/6c5d8f25-9e48-4abb-a1d8-007ea18b9ee0/resourceGroups/MGT-GENERAL-RG/providers/Microsoft.Storage/storageAccounts/mgtmonactlogstgacc001"

    enabled_log = [
      {
        category = "Administrative"
      },
      {
        category = "Security"
      },
      {
        category = "Alert"
      },
      {
        category = "Policy"
      }
    ]
  },
  {
    name                   = "BPM-UAT-DS-KVLOG-01"
    target_resource_module = "azurerm_key_vault"
    target_resource_name   = "CCG-BPM-UAT-KV-01"

    log_analytics_workspace_name = "BPM-UAT-LOG-01"
    storage_account_id           = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Storage/storageAccounts/bpmuatstgacc01"

    enabled_log = [
      {
        category = "AuditEvent"
      },
      {
        category = "AzurePolicyEvaluationDetails"
      }
    ]

    metric = [
      {
        category = "AllMetrics"
        enabled  = false
      }
    ]
  },
  {
    name                   = "BPM-UAT-DS-MYSQLLOG-01"
    target_resource_module = "azurerm_mysql_flexible_server"
    target_resource_name   = "bpm-uat-mysql"

    log_analytics_workspace_name = "BPM-UAT-LOG-01"
    storage_account_id           = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Storage/storageAccounts/bpmuatstgacc01"

    enabled_log = [
      {
        category = "MySqlAuditLogs"
      },
      {
        category = "MySqlSlowLogs"
      }
    ]

    metric = [
      {
        category = "AllMetrics"
        enabled  = false
      }
    ]
  },
  {
    name               = "BPM-UAT-DS-PPLOG-01"
    target_resource_id = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Network/publicIPAddresses/BPM-UAT-PIP-01"

    log_analytics_workspace_name = "BPM-UAT-LOG-01"
    storage_account_id           = "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Storage/storageAccounts/bpmuatstgacc01"

    enabled_log = [
      {
        category = "DDoSProtectionNotifications"
      },
      {
        category = "DDoSMitigationFlowLogs"
      },
      {
        category = "DDoSMitigationReports"
      }
    ]

    metric = [
      {
        category = "AllMetrics"
        enabled  = false
      }
    ]
  },
  {
    name                   = "BPM-UAT-DS-AGWLOG-01"
    target_resource_module = "azurerm_application_gateway"
    target_resource_name   = "BPM-UAT-AGW-01"

    log_analytics_workspace_name   = "BPM-UAT-LOG-01"
    log_analytics_destination_type = "Dedicated"
    storage_account_id             = "/subscriptions/6c5d8f25-9e48-4abb-a1d8-007ea18b9ee0/resourceGroups/MGT-GENERAL-RG/providers/Microsoft.Storage/storageAccounts/mgtnwnprdlogstgacc001"

    enabled_log = [
      {
        # All HTTP requests client IP, URI, response code, latency, backend pool
        category = "ApplicationGatewayAccessLog"
      },
      {
        # WAF rule matches, blocked requests, rule IDs triggered
        category = "ApplicationGatewayFirewallLog"
      },
      {
        # Backend health, connection times, response times per backend
        category = "ApplicationGatewayPerformanceLog"
      }
    ]

    metric = [
      {
        category = "AllMetrics"
        enabled  = false
      }
    ]
  }
]

# Public IP Addresse
public_ips = []

# MongoDB Atlas Private Endpoint (manual request using resource ID / alias)
mongo_private_endpoints = [
  {
    name                           = "BPM-UAT-MONGO-PE-01"
    resource_group_name            = "BPM-UAT-RG"
    location                       = "East Asia"
    subnet_name                    = "BPM-UAT-PE-SUBNET-01"
    private_connection_name        = "pls_698e97668a76ad948a99a20f"
    private_connection_resource_id = "/subscriptions/963d0d29-ad7a-48ae-8091-62149f04a566/resourceGroups/rg_698e91f95832f6a0357a5ef1_psg02le5/providers/Microsoft.Network/privateLinkServices/pls_698e97668a76ad948a99a20f"
    is_manual_connection           = true
    subresource_names              = []
    request_message                = "Private endpoint connection request for MongoDB Atlas cluster ccg-bpm-uat-mongo from BPM UAT environment"
    private_dns_zone_names         = ["mongodb.net"]
  }
]

# Virtual Machine Shutdown Schedule
vm_shutdown_schedules = []

consumption_budget_subscription = []

log_analytics_workspaces = [
  {
    name                = "BPM-UAT-LOG-01"
    resource_group_name = "BPM-UAT-RG"
    location            = "East Asia"
    sku                 = "PerGB2018"
    retention_in_days   = 30
  }
]

data_protection_backup_instances_blob_storage = []

# Azure Monitor Workspace (Prometheus backend for AKS metrics)
monitor_workspaces = [
  {
    name                = "BPM-UAT-MONWS-01"
    resource_group_name = "BPM-UAT-RG"
    location            = "East Asia"
  }
]

# Application Insights (workspace-based APM for the AKS .NET app)
# Telemetry is stored in the existing BPM-UAT-LOG-01 workspace.
application_insights = [
  {
    name                         = "BPM-UAT-APPI-01"
    resource_group_name          = "BPM-UAT-RG"
    location                     = "East Asia"
    application_type             = "web"
    log_analytics_workspace_name = "BPM-UAT-LOG-01"

    tags = {
      Environment = "UAT"
      Owner       = "Business Operations"
      Project     = "BPM"
    }
  }
]

# Azure Managed Grafana — visualizes the AKS Prometheus metrics
# (CPU, memory, network, disk) stored in the BPM-UAT-MONWS-01 Monitor Workspace.
# The module grants the Grafana managed identity Monitoring Reader (subscription)
# + Monitoring Data Reader (on the workspace), and Grafana Admin to the principals below.
# dashboard_grafanas = [
#   {
#     name                          = "BPM-UAT-GRAFANA-01"
#     resource_group_name           = "BPM-UAT-RG"
#     location                      = "East Asia"
#     sku                           = "Standard"
#     grafana_major_version         = 12
#     public_network_access_enabled = true
#     azure_monitor_workspace_names = ["BPM-UAT-MONWS-01"]
#
#     # Grafana Admin access. Object ID below is kickerchlam@chinachemgroup.com.
#     # Add more user/group object IDs as needed.
#     grafana_admin_principal_ids = ["2e39c21a-3e0e-4066-b40a-95200c2a9cbd"]
#
#     tags = {
#       Environment = "UAT"
#       Owner       = "Business Operations"
#       Project     = "BPM"
#     }
#   }
# ]

# ---------------------------------------------------------------------------
# Linux VM Monitoring Agents (AzureMonitorLinuxAgent + DCR)
# Required for guest-OS metrics: filesystem free space, % memory used, etc.
# ---------------------------------------------------------------------------
linux_vm_monitoring_agents = [
  {
    linux_virtual_machine_name   = "BPM-UAT-MIDDLEWARE-VM-01"
    resource_group_name          = "BPM-UAT-RG"
    location                     = "East Asia"
    log_analytics_workspace_name = "BPM-UAT-LOG-01"
    dcr_name                     = "BPM-UAT-DCR-VMINSIGHTS-01"
    collect_syslog               = true
  }
]

# ---------------------------------------------------------------------------
# Monitor Metric Alerts
# All alerts route to BPM-UAT-MONAG-02 (helpdesk@catomind.com).
# Severity: 0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose
# ---------------------------------------------------------------------------
monitor_metric_alerts = [
  # ------------------------- Linux VM (handled by PRTG) --------------------
  # Middleware VM CPU and Memory monitoring is owned by PRTG.
  # The former Azure Monitor alerts (BPM-UAT-MONMA-01/02) were removed to
  # avoid duplicate alerting. Disk usage is likewise covered by PRTG
  # (see the removed BPM-UAT-MONLA-02 log alert).

  # ------------------------- AKS -------------------------------------------
  # DISABLED in UAT: AKS nightly scale-down (20:00->08:00 HKT) for cost saving causes false positives. Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-03"
    resource_group_name    = "BPM-UAT-RG"
    description            = "AKS any node CPU > 80% for 15 minutes"
    severity               = 1
    frequency              = "PT5M"
    window_size            = "PT15M"
    target_resource_module = "azurerm_kubernetes_cluster"
    target_resource_name   = "BPM-UAT-AKS-01"
    criteria = [
      {
        metric_namespace       = "Microsoft.ContainerService/managedClusters"
        metric_name            = "node_cpu_usage_percentage"
        aggregation            = "Maximum"
        operator               = "GreaterThan"
        threshold              = 80
        skip_metric_validation = true
        dimension = [
          { name = "node", operator = "Include", values = ["*"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: AKS nightly scale-down (20:00->08:00 HKT) for cost saving causes false positives. Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-04"
    resource_group_name    = "BPM-UAT-RG"
    description            = "AKS any node memory working set > 80% for 15 minutes"
    severity               = 1
    frequency              = "PT5M"
    window_size            = "PT15M"
    target_resource_module = "azurerm_kubernetes_cluster"
    target_resource_name   = "BPM-UAT-AKS-01"
    criteria = [
      {
        metric_namespace       = "Microsoft.ContainerService/managedClusters"
        metric_name            = "node_memory_working_set_percentage"
        aggregation            = "Maximum"
        operator               = "GreaterThan"
        threshold              = 80
        skip_metric_validation = true
        dimension = [
          { name = "node", operator = "Include", values = ["*"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: AKS nightly scale-down (20:00->08:00 HKT) for cost saving causes false positives. Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-05"
    resource_group_name    = "BPM-UAT-RG"
    description            = "AKS any node disk > 75% for 30 minutes"
    severity               = 1
    frequency              = "PT5M"
    window_size            = "PT30M"
    target_resource_module = "azurerm_kubernetes_cluster"
    target_resource_name   = "BPM-UAT-AKS-01"
    criteria = [
      {
        metric_namespace       = "Microsoft.ContainerService/managedClusters"
        metric_name            = "node_disk_usage_percentage"
        aggregation            = "Maximum"
        operator               = "GreaterThan"
        threshold              = 75
        skip_metric_validation = true
        dimension = [
          { name = "node", operator = "Include", values = ["*"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */

  # ------------------------- App Gateway ----------------------------------
  # DISABLED in UAT: AGW backends are AKS pods that disappear during nightly scale-down (20:00->08:00 HKT, cost saving). Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-06"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Application gateway Alert - Unhealthy Host Count"
    severity               = 0
    frequency              = "PT1M"
    window_size            = "PT5M"
    target_resource_module = "azurerm_application_gateway"
    target_resource_name   = "BPM-UAT-AGW-01"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/applicationGateways"
        metric_name      = "UnhealthyHostCount"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 0
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: AGW backends are AKS pods that disappear during nightly scale-down (20:00->08:00 HKT, cost saving). Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-07"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Application gateway Alert - Failed Requests"
    severity               = 2
    frequency              = "PT1M"
    window_size            = "PT5M"
    target_resource_module = "azurerm_application_gateway"
    target_resource_name   = "BPM-UAT-AGW-01"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/applicationGateways"
        metric_name      = "FailedRequests"
        aggregation      = "Total"
        operator         = "GreaterThan"
        threshold        = 10
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: AGW backends are AKS pods that disappear during nightly scale-down (20:00->08:00 HKT, cost saving). Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-08"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Application gateway Alert - Healthy Host Count"
    severity               = 0
    frequency              = "PT1M"
    window_size            = "PT5M"
    target_resource_module = "azurerm_application_gateway"
    target_resource_name   = "BPM-UAT-AGW-01"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/applicationGateways"
        metric_name      = "HealthyHostCount"
        aggregation      = "Average"
        operator         = "LessThan"
        threshold        = 1
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: AGW backends are AKS pods that disappear during nightly scale-down (20:00->08:00 HKT, cost saving). Uncomment in prod.
  /*
  {
    name                   = "BPM-UAT-MONMA-09"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Application gateway Alert - Response Status"
    severity               = 2
    frequency              = "PT1M"
    window_size            = "PT5M"
    target_resource_module = "azurerm_application_gateway"
    target_resource_name   = "BPM-UAT-AGW-01"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/applicationGateways"
        metric_name      = "ResponseStatus"
        aggregation      = "Total"
        operator         = "GreaterThan"
        threshold        = 10
        dimension = [
          { name = "HttpStatusGroup", operator = "Include", values = ["5xx"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */

  # ------------------------- MySQL ----------------------------------------
  {
    name                   = "BPM-UAT-MONMA-10"
    resource_group_name    = "BPM-UAT-RG"
    description            = "MySQL CPU > 85% for 15 minutes"
    severity               = 1
    frequency              = "PT5M"
    window_size            = "PT15M"
    target_resource_module = "azurerm_mysql_flexible_server"
    target_resource_name   = "bpm-uat-mysql"
    criteria = [
      {
        metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
        metric_name      = "cpu_percent"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  {
    name                   = "BPM-UAT-MONMA-11"
    resource_group_name    = "BPM-UAT-RG"
    description            = "MySQL memory > 90% for 15 minutes"
    severity               = 1
    frequency              = "PT5M"
    window_size            = "PT15M"
    target_resource_module = "azurerm_mysql_flexible_server"
    target_resource_name   = "bpm-uat-mysql"
    criteria = [
      {
        metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
        metric_name      = "memory_percent"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 90
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  {
    name                   = "BPM-UAT-MONMA-12"
    resource_group_name    = "BPM-UAT-RG"
    description            = "MySQL storage > 75% for 1 hour"
    severity               = 1
    frequency              = "PT15M"
    window_size            = "PT1H"
    target_resource_module = "azurerm_mysql_flexible_server"
    target_resource_name   = "bpm-uat-mysql"
    criteria = [
      {
        metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
        metric_name      = "storage_percent"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 75
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },

  # ------------------------- Recovery Vault -------------------------------
  {
    name                   = "BPM-UAT-MONMA-13"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Recovery Vault unhealthy backup health event"
    severity               = 0
    frequency              = "PT15M"
    window_size            = "PT1H"
    target_resource_module = "azurerm_recovery_services_vault"
    target_resource_name   = "BPM-UAT-RSV-01"
    criteria = [
      {
        metric_namespace = "Microsoft.RecoveryServices/Vaults"
        metric_name      = "BackupHealthEvent"
        aggregation      = "Count"
        operator         = "GreaterThan"
        threshold        = 0
        dimension = [
          { name = "healthStatus", operator = "Include", values = ["Unhealthy"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },

  # ------------------------- Key Vault / ACR / Public IP -------------------
  {
    name                   = "BPM-UAT-MONMA-14"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Key Vault failed API calls in 15 minutes"
    severity               = 2
    frequency              = "PT5M"
    window_size            = "PT15M"
    target_resource_module = "azurerm_key_vault"
    target_resource_name   = "CCG-BPM-UAT-KV-01"
    criteria = [
      {
        metric_namespace = "Microsoft.KeyVault/vaults"
        metric_name      = "ServiceApiResult"
        aggregation      = "Count"
        operator         = "GreaterThan"
        threshold        = 0
        dimension = [
          { name = "StatusCode", operator = "Include", values = ["4*", "5*"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  {
    name                   = "BPM-UAT-MONMA-15"
    resource_group_name    = "BPM-UAT-RG"
    description            = "ACR storage used > 80% of Premium quota (500 GB)"
    severity               = 2
    frequency              = "PT1H"
    window_size            = "PT1H"
    target_resource_module = "azurerm_container_registry"
    target_resource_name   = "ccgbpmuatacr01"
    criteria = [
      {
        metric_namespace = "Microsoft.ContainerRegistry/registries"
        metric_name      = "StorageUsed"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 429496729600 # 400 GB ~ 80% of 500 GB
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  {
    name                   = "BPM-UAT-MONMA-16"
    resource_group_name    = "BPM-UAT-RG"
    description            = "Public IP under DDoS attack (requires DDoS Standard plan)"
    severity               = 0
    frequency              = "PT1M"
    window_size            = "PT5M"
    target_resource_module = "azurerm_public_ip_application_gateway_frontend"
    target_resource_name   = "BPM-UAT-PIP-01"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/publicIPAddresses"
        metric_name      = "IfUnderDDoSAttack"
        aggregation      = "Maximum"
        operator         = "GreaterThanOrEqual"
        threshold        = 1
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },

  # ------------------------- Load Balancer (AKS internal) ------------------
  # Targets the AKS-managed kubernetes-internal LB in MC_BPM-UAT-RG_BPM-UAT-AKS-01_eastasia.
  # This LB has no outbound rules (AKS outbound_type = userDefinedRouting), so
  # SNAT metrics will always read 0. Kept for completeness; SNAT pressure is
  # monitored on the hub Azure Firewall in the Landing Zone.
  # DISABLED in UAT: backends emptied during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                = "BPM-UAT-MONMA-17"
    resource_group_name = "BPM-UAT-RG"
    description         = "Load balancer Alert - Health Probe Status"
    severity            = 0
    frequency           = "PT1M"
    window_size         = "PT5M"
    scopes = [
      "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/mc_bpm-uat-rg_bpm-uat-aks-01_eastasia/providers/Microsoft.Network/loadBalancers/kubernetes-internal"
    ]
    target_resource_type     = "Microsoft.Network/loadBalancers"
    target_resource_location = "East Asia"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/loadBalancers"
        metric_name      = "DipAvailability"
        aggregation      = "Average"
        operator         = "LessThan"
        threshold        = 100
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: backends emptied during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                = "BPM-UAT-MONMA-18"
    resource_group_name = "BPM-UAT-RG"
    description         = "Load balancer Alert - Data Path Availability"
    severity            = 0
    frequency           = "PT1M"
    window_size         = "PT5M"
    scopes = [
      "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/mc_bpm-uat-rg_bpm-uat-aks-01_eastasia/providers/Microsoft.Network/loadBalancers/kubernetes-internal"
    ]
    target_resource_type     = "Microsoft.Network/loadBalancers"
    target_resource_location = "East Asia"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/loadBalancers"
        metric_name      = "VipAvailability"
        aggregation      = "Average"
        operator         = "LessThan"
        threshold        = 100
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: backends emptied during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                = "BPM-UAT-MONMA-19"
    resource_group_name = "BPM-UAT-RG"
    description         = "Load balancer Alert - Used SNAT Ports"
    severity            = 0
    frequency           = "PT1M"
    window_size         = "PT5M"
    scopes = [
      "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/mc_bpm-uat-rg_bpm-uat-aks-01_eastasia/providers/Microsoft.Network/loadBalancers/kubernetes-internal"
    ]
    target_resource_type     = "Microsoft.Network/loadBalancers"
    target_resource_location = "East Asia"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/loadBalancers"
        metric_name      = "UsedSnatPorts"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 800
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  },
  */
  # DISABLED in UAT: backends emptied during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                = "BPM-UAT-MONMA-20"
    resource_group_name = "BPM-UAT-RG"
    description         = "Load balancer Alert - SNAT Connection Count"
    severity            = 0
    frequency           = "PT1M"
    window_size         = "PT5M"
    scopes = [
      "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/mc_bpm-uat-rg_bpm-uat-aks-01_eastasia/providers/Microsoft.Network/loadBalancers/kubernetes-internal"
    ]
    target_resource_type     = "Microsoft.Network/loadBalancers"
    target_resource_location = "East Asia"
    criteria = [
      {
        metric_namespace = "Microsoft.Network/loadBalancers"
        metric_name      = "SnatConnectionCount"
        aggregation      = "Total"
        operator         = "GreaterThan"
        threshold        = 0
        dimension = [
          { name = "ConnectionState", operator = "Include", values = ["Failed"] }
        ]
      }
    ]
    action = [{ action_group_name = "BPM-UAT-MONAG-02" }]
  }
  */
]

# ---------------------------------------------------------------------------
# Monitor Scheduled Query Rules (Log Alerts v2)
# Used for VM heartbeat, guest filesystem free space, AKS pod health.
# All alerts route to BPM-UAT-MONAG-02 (helpdesk@catomind.com).
# ---------------------------------------------------------------------------
monitor_scheduled_query_rules = [
  # NOTE: Middleware VM heartbeat/availability and disk usage are monitored by
  # PRTG. The former BPM-UAT-MONLA-01 (heartbeat) and BPM-UAT-MONLA-02 (managed
  # disk > 75%) log alerts were removed to avoid duplicate alerting.

  # AKS failed pods
  # DISABLED in UAT: pods enter Failed during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                              = "BPM-UAT-MONLA-03"
    resource_group_name               = "BPM-UAT-RG"
    location                          = "East Asia"
    display_name                      = "AKS failed pods sustained"
    description                       = "Pods in Failed phase observed on the AKS cluster for at least 10 minutes."
    severity                          = 1
    evaluation_frequency              = "PT5M"
    window_duration                   = "PT10M"
    mute_actions_after_alert_duration = "PT1H"
    scope_resource_module             = "azurerm_log_analytics_workspace"
    scope_resource_name               = "BPM-UAT-LOG-01"
    criteria = {
      query = <<-KQL
        KubePodInventory
        | where ClusterName == "BPM-UAT-AKS-01"
        | where PodStatus == "Failed"
        | summarize FailedPods = dcount(Name) by Namespace, _ResourceId, bin(TimeGenerated, 5m)
      KQL
      operator                = "GreaterThan"
      threshold               = 0
      time_aggregation_method = "Maximum"
      metric_measure_column   = "FailedPods"
      resource_id_column      = "_ResourceId"
      dimension = [
        { name = "Namespace", operator = "Include", values = ["*"] }
      ]
      failing_periods = {
        number_of_evaluation_periods             = 2
        minimum_failing_periods_to_trigger_alert = 2
      }
    }
    action = {
      action_group_names = ["BPM-UAT-MONAG-02"]
    }
  },
  */

  # AKS container restarts
  # DISABLED in UAT: pod evictions during nightly AKS scale-down (20:00->08:00 HKT, cost saving) cause restart spikes — false-positive. Uncomment in prod.
  /*
  {
    name                              = "BPM-UAT-MONLA-04"
    resource_group_name               = "BPM-UAT-RG"
    location                          = "East Asia"
    display_name                      = "AKS container restart spike"
    description                       = "More than 5 container restarts observed for any container in the last 15 minutes."
    severity                          = 2
    evaluation_frequency              = "PT15M"
    window_duration                   = "PT15M"
    mute_actions_after_alert_duration = "PT1H"
    scope_resource_module             = "azurerm_log_analytics_workspace"
    scope_resource_name               = "BPM-UAT-LOG-01"
    criteria = {
      query = <<-KQL
        KubePodInventory
        | where ClusterName == "BPM-UAT-AKS-01"
        | extend Restarts = todouble(ContainerRestartCount)
        | summarize MaxRestarts = max(Restarts) by ContainerName, Namespace, _ResourceId, bin(TimeGenerated, 15m)
        | where MaxRestarts > 5
      KQL
      operator                = "GreaterThan"
      threshold               = 0
      time_aggregation_method = "Count"
      resource_id_column      = "_ResourceId"
      dimension = [
        { name = "ContainerName", operator = "Include", values = ["*"] },
        { name = "Namespace", operator = "Include", values = ["*"] }
      ]
      failing_periods = {
        number_of_evaluation_periods             = 2
        minimum_failing_periods_to_trigger_alert = 2
      }
    }
    action = {
      action_group_names = ["BPM-UAT-MONAG-02"]
    }
  },
  */

  # AKS unschedulable pods
  # DISABLED in UAT: pods stay Pending during nightly AKS scale-down (20:00->08:00 HKT, cost saving) — would false-positive. Uncomment in prod.
  /*
  {
    name                              = "BPM-UAT-MONLA-05"
    resource_group_name               = "BPM-UAT-RG"
    location                          = "East Asia"
    display_name                      = "AKS unschedulable pods"
    description                       = "Pods stuck in Pending phase on the AKS cluster (autoscaler unable to schedule)."
    severity                          = 2
    evaluation_frequency              = "PT5M"
    window_duration                   = "PT10M"
    mute_actions_after_alert_duration = "PT1H"
    scope_resource_module             = "azurerm_log_analytics_workspace"
    scope_resource_name               = "BPM-UAT-LOG-01"
    criteria = {
      query = <<-KQL
        KubePodInventory
        | where ClusterName == "BPM-UAT-AKS-01"
        | where PodStatus == "Pending"
        | summarize PendingPods = dcount(Name) by Namespace, _ResourceId, bin(TimeGenerated, 5m)
        | where PendingPods > 0
      KQL
      operator                = "GreaterThan"
      threshold               = 0
      time_aggregation_method = "Maximum"
      metric_measure_column   = "PendingPods"
      resource_id_column      = "_ResourceId"
      dimension = [
        { name = "Namespace", operator = "Include", values = ["*"] }
      ]
      failing_periods = {
        number_of_evaluation_periods             = 2
        minimum_failing_periods_to_trigger_alert = 2
      }
    }
    action = {
      action_group_names = ["BPM-UAT-MONAG-02"]
    }
  },
  */

  # Recovery Vault backup job failure
  # 1-day window already debounces flapping â€” no failing_periods needed.
  {
    name                              = "BPM-UAT-MONLA-06"
    resource_group_name               = "BPM-UAT-RG"
    location                          = "East Asia"
    display_name                      = "Recovery Vault backup job not completed"
    description                       = "Any backup job did not complete successfully in the last 24 hours."
    severity                          = 1
    evaluation_frequency              = "PT1H"
    window_duration                   = "P1D"
    mute_actions_after_alert_duration = "PT1H"
    scope_resource_module             = "azurerm_log_analytics_workspace"
    scope_resource_name               = "BPM-UAT-LOG-01"
    criteria = {
      query                   = <<-KQL
        AddonAzureBackupJobs
        | where JobOperation == "Backup"
        | where JobStatus != "Completed"
        | summarize FailedJobs = count() by BackupItemUniqueId, _ResourceId
      KQL
      operator                = "GreaterThan"
      threshold               = 0
      time_aggregation_method = "Count"
      resource_id_column      = "_ResourceId"
      dimension = [
        { name = "BackupItemUniqueId", operator = "Include", values = ["*"] }
      ]
    }
    action = {
      action_group_names = ["BPM-UAT-MONAG-02"]
    }
  }
]
