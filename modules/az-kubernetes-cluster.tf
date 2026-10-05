resource "azurerm_kubernetes_cluster" "main" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
  }

  name                      = each.value.name
  location                  = each.value.location
  resource_group_name       = each.value.resource_group_name
  dns_prefix                = coalesce(each.value.dns_prefix, each.value.name)
  kubernetes_version        = each.value.kubernetes_version
  sku_tier                  = coalesce(each.value.sku_tier, "Free")
  automatic_upgrade_channel = each.value.automatic_upgrade_channel != null ? each.value.automatic_upgrade_channel : null
  node_os_upgrade_channel   = each.value.node_os_upgrade_channel != null ? each.value.node_os_upgrade_channel : null

  private_cluster_enabled             = coalesce(each.value.private_cluster_enabled, false)
  private_dns_zone_id                 = each.value.private_dns_zone_id
  private_cluster_public_fqdn_enabled = coalesce(each.value.private_cluster_public_fqdn_enabled, false)

  azure_policy_enabled              = coalesce(each.value.azure_policy_enabled, false)
  http_application_routing_enabled  = coalesce(each.value.http_application_routing_enabled, false)
  role_based_access_control_enabled = coalesce(each.value.role_based_access_control_enabled, true)

  dynamic "default_node_pool" {
    for_each = [each.value.default_node_pool]
    content {
      name                         = default_node_pool.value.name
      vm_size                      = default_node_pool.value.vm_size
      node_count                   = default_node_pool.value.node_count
      auto_scaling_enabled         = coalesce(default_node_pool.value.enable_auto_scaling, false)
      min_count                    = default_node_pool.value.min_count
      max_count                    = default_node_pool.value.max_count
      max_pods                     = default_node_pool.value.max_pods
      os_disk_size_gb              = default_node_pool.value.os_disk_size_gb
      os_disk_type                 = coalesce(default_node_pool.value.os_disk_type, "Managed")
      vnet_subnet_id               = azurerm_subnet.main[default_node_pool.value.subnet_name].id
      zones                        = default_node_pool.value.zones
      host_encryption_enabled      = coalesce(default_node_pool.value.enable_host_encryption, false)
      node_public_ip_enabled       = coalesce(default_node_pool.value.enable_node_public_ip, false)
      orchestrator_version         = default_node_pool.value.orchestrator_version
      temporary_name_for_rotation  = default_node_pool.value.temporary_name_for_rotation
      only_critical_addons_enabled = coalesce(default_node_pool.value.only_critical_addons_enabled, false)

      dynamic "upgrade_settings" {
        for_each = default_node_pool.value.upgrade_settings != null ? [default_node_pool.value.upgrade_settings] : []
        content {
          max_surge                     = upgrade_settings.value.max_surge
          drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
          node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
        }
      }

      tags = default_node_pool.value.tags
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
      identity_ids = identity.value.type != "SystemAssigned" ? (
        identity.value.identity_ids != null ? identity.value.identity_ids : (
          identity.value.identity_names != null ? [for identity_name in identity.value.identity_names : azurerm_user_assigned_identity.main[identity_name].id] : []
        )
      ) : null
    }
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin      = network_profile.value.network_plugin
      network_policy      = network_profile.value.network_policy
      dns_service_ip      = network_profile.value.dns_service_ip
      service_cidr        = network_profile.value.service_cidr
      load_balancer_sku   = coalesce(network_profile.value.load_balancer_sku, "standard")
      outbound_type       = coalesce(network_profile.value.outbound_type, "loadBalancer")
      network_plugin_mode = network_profile.value.network_plugin_mode
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.azure_active_directory_role_based_access_control != null ? [each.value.azure_active_directory_role_based_access_control] : []
    content {
      azure_rbac_enabled     = coalesce(azure_active_directory_role_based_access_control.value.azure_rbac_enabled, false)
      tenant_id              = coalesce(azure_active_directory_role_based_access_control.value.tenant_id, var.tenant_id)
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
    }
  }

  dynamic "oms_agent" {
    for_each = each.value.oms_agent != null ? [each.value.oms_agent] : []
    content {
      log_analytics_workspace_id      = oms_agent.value.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = coalesce(oms_agent.value.msi_auth_for_monitoring_enabled, true)
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = each.value.key_vault_secrets_provider != null ? [each.value.key_vault_secrets_provider] : []
    content {
      secret_rotation_enabled  = coalesce(key_vault_secrets_provider.value.secret_rotation_enabled, false)
      secret_rotation_interval = coalesce(key_vault_secrets_provider.value.secret_rotation_interval, "2m")
    }
  }

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = coalesce(maintenance_window.value.allowed, [])
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
      dynamic "not_allowed" {
        for_each = coalesce(maintenance_window.value.not_allowed, [])
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = each.value.maintenance_window_auto_upgrade != null ? [each.value.maintenance_window_auto_upgrade] : []
    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      week_index   = maintenance_window_auto_upgrade.value.week_index
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      start_date   = maintenance_window_auto_upgrade.value.start_date

      dynamic "not_allowed" {
        for_each = coalesce(maintenance_window_auto_upgrade.value.not_allowed, [])
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = each.value.maintenance_window_node_os != null ? [each.value.maintenance_window_node_os] : []
    content {
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      duration     = maintenance_window_node_os.value.duration
      day_of_week  = maintenance_window_node_os.value.day_of_week
      week_index   = maintenance_window_node_os.value.week_index
      day_of_month = maintenance_window_node_os.value.day_of_month
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      start_date   = maintenance_window_node_os.value.start_date

      dynamic "not_allowed" {
        for_each = coalesce(maintenance_window_node_os.value.not_allowed, [])
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "microsoft_defender" {
    for_each = each.value.microsoft_defender != null ? [each.value.microsoft_defender] : []
    content {
      log_analytics_workspace_id = microsoft_defender.value.log_analytics_workspace_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = each.value.monitor_metrics != null ? [each.value.monitor_metrics] : []
    content {
      annotations_allowed = monitor_metrics.value.annotations_allowed
      labels_allowed      = monitor_metrics.value.labels_allowed
    }
  }

  dynamic "service_mesh_profile" {
    for_each = each.value.service_mesh_profile != null ? [each.value.service_mesh_profile] : []
    content {
      mode                             = service_mesh_profile.value.mode
      revisions                        = service_mesh_profile.value.revisions
      internal_ingress_gateway_enabled = coalesce(service_mesh_profile.value.internal_ingress_gateway_enabled, false)
      external_ingress_gateway_enabled = coalesce(service_mesh_profile.value.external_ingress_gateway_enabled, false)
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.main,
    azurerm_subnet.main
  ]
}

# AKS Node Pool (additional node pools)
resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each = {
    for node_pool in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for node_pool in coalesce(aks.additional_node_pools, []) : merge(node_pool, {
          aks_name = aks.name
        })
      ]
    ]), []) : "${node_pool.aks_name}-${node_pool.name}" => node_pool
  }

  name                        = each.value.name
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.main[each.value.aks_name].id
  vm_size                     = each.value.vm_size
  node_count                  = each.value.node_count
  auto_scaling_enabled        = coalesce(each.value.enable_auto_scaling, false)
  min_count                   = each.value.min_count
  max_count                   = each.value.max_count
  max_pods                    = each.value.max_pods
  os_disk_size_gb             = each.value.os_disk_size_gb
  os_disk_type                = coalesce(each.value.os_disk_type, "Managed")
  vnet_subnet_id              = each.value.subnet_name != null ? azurerm_subnet.main[each.value.subnet_name].id : null
  zones                       = each.value.zones
  host_encryption_enabled     = coalesce(each.value.enable_host_encryption, false)
  node_public_ip_enabled      = coalesce(each.value.enable_node_public_ip, false)
  orchestrator_version        = each.value.orchestrator_version
  temporary_name_for_rotation = each.value.temporary_name_for_rotation
  node_taints                 = each.value.node_taints
  node_labels                 = each.value.node_labels

  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []
    content {
      max_surge                     = upgrade_settings.value.max_surge
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

# Role Assignment: Grant AKS access to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  for_each = {
    for aks_acr in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for acr_name in coalesce(aks.attach_acr_names, []) : {
          aks_name = aks.name
          acr_name = acr_name
        }
      ]
    ]), []) : "${aks_acr.aks_name}-${aks_acr.acr_name}" => aks_acr
  }

  principal_id                     = azurerm_kubernetes_cluster.main[each.value.aks_name].kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main[each.value.acr_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_container_registry.main
  ]
}

resource "azurerm_role_assignment" "identity_aks_contributor" {
  for_each = {
    for aks_identity in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for identity_name in coalesce(aks.allow_identity_access_contributor, []) : {
          aks_name      = aks.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${aks_identity.aks_name}-${aks_identity.identity_name}" => aks_identity
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "Azure Kubernetes Service Contributor Role"
  scope                            = azurerm_kubernetes_cluster.main[each.value.aks_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_user_assigned_identity.main
  ]
}

# Grant VM managed identities access to AKS for kubectl
resource "azurerm_role_assignment" "identity_aks_cluster_user" {
  for_each = {
    for aks_identity in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for identity_name in coalesce(aks.allow_identity_access_user, []) : {
          aks_name      = aks.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${aks_identity.aks_name}-${aks_identity.identity_name}" => aks_identity
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  scope                            = azurerm_kubernetes_cluster.main[each.value.aks_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_user_assigned_identity.main
  ]
}

# ---------------------------------------------------------------------------
# Fix: LinkedAuthorizationFailed - Microsoft.Network/virtualNetworks/subnets/join/action
#
# When AKS creates a Service of type=LoadBalancer (internal), the AKS cluster
# identity must have Microsoft.Network/virtualNetworks/subnets/join/action on
# the subnet where the internal LB IP is provisioned.
# "Network Contributor" covers this action at subnet scope (least-privilege).
#
# The principal is the AKS cluster's own identity[0].principal_id
# (SystemAssigned: confirmed via `az aks show` - principalId: 37418faf-ee55-40ac-843d-4f499c5e9a7f).
#
# Scope choice:
#   - Subnet scope (default below): sufficient for a single-subnet setup.
#   - VNet scope (see commented block below): use only when AKS provisions
#     LBs across multiple subnets or the error persists after applying.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if coalesce(aks.grant_subnet_network_contributor, false)
  }

  # The AKS control-plane identity that provisions internal load balancers.
  # For SystemAssigned AKS: this is identity[0].principal_id.
  principal_id = azurerm_kubernetes_cluster.main[each.key].identity[0].principal_id

  role_definition_name = "Network Contributor"

  # Scope: the default node-pool subnet (least-privilege).
  # AKS attaches the internal LB NIC here and requires subnets/join/action.
  scope = azurerm_subnet.main[each.value.default_node_pool.subnet_name].id

  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_subnet.main
  ]
}

# ---------------------------------------------------------------------------
# OPTIONAL – VNet-scope alternative (uncomment if subnet scope is not enough)
#
# Use this instead of the subnet-scope assignment above when:
#   - AKS provisions internal LBs on subnets other than the node-pool subnet, OR
#   - You still see subnets/join/action errors after applying subnet scope.
#
# WARNING: Network Contributor at VNet scope covers ALL subnets in the VNet.
# Only escalate here after confirming subnet scope is insufficient.
# ---------------------------------------------------------------------------
# resource "azurerm_role_assignment" "aks_vnet_network_contributor" {
#   for_each = {
#     for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
#     if coalesce(aks.grant_subnet_network_contributor, false)
#   }
#
#   principal_id                     = azurerm_kubernetes_cluster.main[each.key].identity[0].principal_id
#   role_definition_name             = "Network Contributor"
#   scope                            = azurerm_virtual_network.main["BPM-UAT-VNET-01"].id
#   skip_service_principal_aad_check = true
#
#   depends_on = [
#     azurerm_kubernetes_cluster.main,
#     azurerm_virtual_network.main
#   ]
# }

resource "azurerm_role_assignment" "identity_aks_subnet_network_contributor" {
  for_each = {
    for item in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for identity_name in coalesce(aks.allow_identity_subnet_network_contributor, []) : {
          aks_name      = aks.name
          identity_name = identity_name
          subnet_name   = aks.default_node_pool.subnet_name
        }
      ]
    ]), []) : "${item.aks_name}-${item.identity_name}" => item
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_subnet.main[each.value.subnet_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_user_assigned_identity.main,
    azurerm_subnet.main
  ]
}

resource "azurerm_role_assignment" "identity_aks_rbac_admin" {
  for_each = {
    for aks_identity in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for identity_name in coalesce(aks.allow_identity_access_admin, []) : {
          aks_name      = aks.name
          identity_name = identity_name
        }
      ]
    ]), []) : "${aks_identity.aks_name}-${aks_identity.identity_name}" => aks_identity
  }

  principal_id                     = azurerm_user_assigned_identity.main[each.value.identity_name].principal_id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                            = azurerm_kubernetes_cluster.main[each.value.aks_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_user_assigned_identity.main
  ]
}

resource "azurerm_role_assignment" "principal_aks_rbac_admin" {
  for_each = {
    for aks_principal in coalesce(flatten([
      for aks in coalesce(var.kubernetes_clusters, []) : [
        for principal_id in coalesce(aks.allow_principal_access_admin, []) : {
          aks_name     = aks.name
          principal_id = principal_id
        }
      ]
    ]), []) : "${aks_principal.aks_name}-${aks_principal.principal_id}" => aks_principal
  }

  principal_id                     = each.value.principal_id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                            = azurerm_kubernetes_cluster.main[each.value.aks_name].id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

# Grant AKS kubelet identity Monitoring Metrics Publisher on the Log Analytics workspace
# so the OMS agent can send container logs when msi_auth_for_monitoring_enabled = true.
resource "azurerm_role_assignment" "aks_oms_monitoring_publisher" {
  for_each = {
    for aks in coalesce(var.kubernetes_clusters, []) : aks.name => aks
    if aks.oms_agent != null && aks.oms_agent.log_analytics_workspace_id != null
  }

  principal_id                     = azurerm_kubernetes_cluster.main[each.key].kubelet_identity[0].object_id
  role_definition_name             = "Monitoring Metrics Publisher"
  scope                            = each.value.oms_agent.log_analytics_workspace_id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}
