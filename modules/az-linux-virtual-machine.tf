resource "azurerm_network_interface" "linux_main" {
  for_each = {
    for network_interface_name, network_interface in flatten([
      for linux_virtual_machine_name, linux_virtual_machine in coalesce(var.linux_virtual_machines, []) : [
        for network_interface_name, network_interface in linux_virtual_machine.network_interfaces : {
          network_interface = network_interface
        }
      ]
    ]) : network_interface.network_interface.name => network_interface.network_interface
  }

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    iterator = ip_configuration

    content {
      name                                               = ip_configuration.value.name
      subnet_id                                          = azurerm_subnet.main[ip_configuration.value.subnet_name].id
      gateway_load_balancer_frontend_ip_configuration_id = ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id
      private_ip_address_allocation                      = ip_configuration.value.private_ip_address_allocation
      private_ip_address                                 = ip_configuration.value.private_ip_address
      private_ip_address_version                         = ip_configuration.value.private_ip_address_version
      primary                                            = ip_configuration.value.primary
      public_ip_address_id                               = ip_configuration.value.public_ip_name != null ? azurerm_public_ip.main[ip_configuration.value.public_ip_name].id : null
    }
  }

  depends_on = [
    azurerm_subnet.main
  ]
}

locals {
  # Pre-compute identity IDs for VMs to ensure proper dependency resolution
  vm_identity_ids = {
    for vm in coalesce(var.linux_virtual_machines, []) : vm.name => (
      vm.identity != null && vm.identity.identity_names != null && length(vm.identity.identity_names) > 0
      ? [for name in vm.identity.identity_names : azurerm_user_assigned_identity.main[name].id]
      : []
    )
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each = {
    for linux_virtual_machine_name, linux_virtual_machine in coalesce(var.linux_virtual_machines, []) : linux_virtual_machine.name => linux_virtual_machine
  }

  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  size                            = each.value.size
  zone                            = each.value.zone
  computer_name                   = each.value.computer_name
  admin_username                  = var.linux_virtual_machines_admin_username
  admin_password                  = var.linux_virtual_machines_admin_password
  disable_password_authentication = each.value.disable_password_authentication
  network_interface_ids           = [for network_interface in each.value.network_interfaces : azurerm_network_interface.linux_main[network_interface.name].id]
  encryption_at_host_enabled      = each.value.encryption_at_host_enabled

  source_image_id                                        = each.value.source_image_id
  allow_extension_operations                             = each.value.allow_extension_operations
  availability_set_id                                    = each.value.availability_set_id
  bypass_platform_safety_checks_on_user_schedule_enabled = each.value.bypass_platform_safety_checks_on_user_schedule_enabled
  capacity_reservation_group_id                          = each.value.capacity_reservation_group_id
  custom_data                                            = each.value.custom_data
  dedicated_host_id                                      = each.value.dedicated_host_id
  dedicated_host_group_id                                = each.value.dedicated_host_group_id
  edge_zone                                              = each.value.edge_zone
  eviction_policy                                        = each.value.eviction_policy
  extensions_time_budget                                 = each.value.extensions_time_budget
  license_type                                           = each.value.license_type
  max_bid_price                                          = each.value.max_bid_price
  patch_assessment_mode                                  = each.value.patch_assessment_mode
  patch_mode                                             = each.value.patch_mode
  platform_fault_domain                                  = each.value.platform_fault_domain
  priority                                               = each.value.priority
  provision_vm_agent                                     = each.value.provision_vm_agent
  proximity_placement_group_id                           = each.value.proximity_placement_group_id
  reboot_setting                                         = each.value.reboot_setting
  secure_boot_enabled                                    = each.value.secure_boot_enabled
  user_data                                              = each.value.user_data
  virtual_machine_scale_set_id                           = each.value.virtual_machine_scale_set_id
  vtpm_enabled                                           = each.value.vtpm_enabled

  os_disk {
    name                 = each.value.os_disk.name
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  dynamic "source_image_reference" {
    for_each = each.value.source_image_reference != null ? [each.value.source_image_reference] : []
    iterator = source_image_reference

    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics != null ? each.value.boot_diagnostics.storage_account_uri : null
  }

  dynamic "admin_ssh_key" {
    for_each = { for index, admin_ssh_key in coalesce(each.value.admin_ssh_keys, []) : index => admin_ssh_key }
    iterator = admin_ssh_key

    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "gallery_application" {
    for_each = { for index, gallery_application in coalesce(each.value.gallery_applications, []) : index => gallery_application }
    iterator = gallery_application

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }

  dynamic "plan" {
    for_each = each.value.plan != null ? [each.value.plan] : []
    iterator = plan

    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  dynamic "secret" {
    for_each = { for index, secret in coalesce(each.value.secrets, []) : index => secret }
    iterator = secret

    content {
      key_vault_id = secret.value.key_vault_id

      dynamic "certificate" {
        for_each = { for index, certificate in coalesce(secret.value.certificates, []) : index => certificate }
        iterator = certificate

        content {
          url = certificate.value.url
        }
      }
    }
  }

  dynamic "termination_notification" {
    for_each = each.value.termination_notification != null ? [each.value.termination_notification] : []
    iterator = termination_notification

    content {
      enabled = termination_notification.value.enabled
      timeout = termination_notification.value.timeout
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    iterator = identity

    content {
      type = identity.value.type
      identity_ids = (
        length(local.vm_identity_ids[each.value.name]) > 0
        ? local.vm_identity_ids[each.value.name]
        : identity.value.identity_ids
      )
    }
  }

  lifecycle {
    ignore_changes = [
      admin_username,
      admin_password
    ]
  }

  depends_on = [
    azurerm_network_interface.linux_main,
    azurerm_user_assigned_identity.main
  ]
}

resource "azurerm_managed_disk" "linux_data_disk" {
  for_each = {
    for disk in flatten([
      for linux_virtual_machine in coalesce(var.linux_virtual_machines, []) : [
        for data_disk in coalesce(linux_virtual_machine.data_disks, []) : merge(data_disk, {
          vm_name             = linux_virtual_machine.name
          resource_group_name = linux_virtual_machine.resource_group_name
          location            = linux_virtual_machine.location
          zone                = linux_virtual_machine.zone
        })
      ]
    ]) : disk.name => disk
  }

  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb
  zone                 = each.value.zone

  tags = each.value.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "linux_main" {
  for_each = {
    for disk in flatten([
      for linux_virtual_machine in coalesce(var.linux_virtual_machines, []) : [
        for data_disk in coalesce(linux_virtual_machine.data_disks, []) : merge(data_disk, {
          vm_name = linux_virtual_machine.name
        })
      ]
    ]) : disk.name => disk
  }

  managed_disk_id    = azurerm_managed_disk.linux_data_disk[each.value.name].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[each.value.vm_name].id
  lun                = each.value.lun
  caching            = each.value.caching

  depends_on = [
    azurerm_linux_virtual_machine.main,
    azurerm_managed_disk.linux_data_disk
  ]
}

resource "azurerm_backup_protected_vm" "linux_main" {
  for_each = {
    for index, backup_protected_vm in coalesce(flatten([
      for index, linux_virtual_machine in coalesce(var.linux_virtual_machines, []) : [
        for index, backup_protected_vm in coalesce([linux_virtual_machine.backup_protected_vm], []) : merge(backup_protected_vm, {
          resource_group_name        = linux_virtual_machine.resource_group_name
          linux_virtual_machine_name = linux_virtual_machine.name
        })
      ]
    ]), []) : backup_protected_vm.linux_virtual_machine_name => backup_protected_vm
  }
  resource_group_name = each.value.resource_group_name
  recovery_vault_name = each.value.recovery_vault_name
  source_vm_id        = each.value.source_vm_id != null ? each.value.source_vm_id : azurerm_linux_virtual_machine.main[each.value.linux_virtual_machine_name].id
  backup_policy_id    = each.value.backup_policy_id != null ? each.value.backup_policy_id : azurerm_backup_policy_vm.main[each.value.backup_policy_name].id
  exclude_disk_luns   = each.value.exclude_disk_luns
  include_disk_luns   = each.value.include_disk_luns
  protection_state    = each.value.protection_state

  depends_on = [
    azurerm_linux_virtual_machine.main,
    azurerm_recovery_services_vault.main,
    azurerm_backup_policy_vm.main
  ]
}
