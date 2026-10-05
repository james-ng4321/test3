resource "azurerm_network_interface" "main" {
  for_each = {
    for network_interface_name, network_interface in flatten([
      for windows_virtual_machine_name, windows_virtual_machine in coalesce(var.windows_virtual_machines, []) : [
        for network_interface_name, network_interface in windows_virtual_machine.network_interfaces : {
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

resource "azurerm_windows_virtual_machine" "main" {
  for_each = {
    for windows_virtual_machine_name, windows_virtual_machine in coalesce(var.windows_virtual_machines, []) : windows_virtual_machine.name => windows_virtual_machine
  }

  name                       = each.value.name
  resource_group_name        = each.value.resource_group_name
  location                   = each.value.location
  size                       = each.value.size
  zone                       = each.value.zone
  computer_name              = each.value.computer_name
  admin_username             = var.windows_virtual_machines_admin_username
  admin_password             = var.windows_virtual_machines_admin_password
  network_interface_ids      = [for network_interface in each.value.network_interfaces : azurerm_network_interface.main[network_interface.name].id]
  encryption_at_host_enabled = each.value.encryption_at_host_enabled

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
  hotpatching_enabled                                    = each.value.hotpatching_enabled
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
  timezone                                               = each.value.timezone
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
    storage_account_uri = each.value.boot_diagnostics.storage_account_uri
  }

  dynamic "additional_unattend_content" {
    for_each = { for index, additional_unattend_content in coalesce(each.value.additional_unattend_contents, []) : index => additional_unattend_content }
    iterator = additional_unattend_content

    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
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
      key_vault_id = sercret.value.key_vault_id

      dynamic "certificate" {
        for_each = { for index, certificate in coalesce(secret.value.certificates, []) : index => certificate }
        iterator = certificate

        content {
          store = certificate.value.store
          url   = certificate.value.url
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

  dynamic "winrm_listener" {
    for_each = { for index, winrm_listener in coalesce(each.value.winrm_listeners, []) : index => winrm_listener }
    iterator = winrm_listener

    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = winrm_listener.value.certificate_url
    }
  }

  lifecycle {
    ignore_changes = [
      admin_username,
      admin_password
    ]
  }

  depends_on = [
    azurerm_network_interface.main
  ]
}

resource "azurerm_backup_protected_vm" "main" {
  for_each = {
    for index, backup_protected_vm in coalesce(flatten([
      for index, windows_virtual_machine in coalesce(var.windows_virtual_machines, []) : [
        for index, backup_protected_vm in coalesce([windows_virtual_machine.backup_protected_vm], []) : merge(backup_protected_vm, {
          resource_group_name          = windows_virtual_machine.resource_group_name
          windows_virtual_machine_name = windows_virtual_machine.name
        })
      ]
    ]), []) : backup_protected_vm.windows_virtual_machine_name => backup_protected_vm
  }
  resource_group_name = each.value.resource_group_name
  recovery_vault_name = each.value.recovery_vault_name
  source_vm_id        = each.value.source_vm_id != null ? each.value.source_vm_id : azurerm_windows_virtual_machine.main[each.value.windows_virtual_machine_name].id
  backup_policy_id    = each.value.backup_policy_id != null ? each.value.backup_policy_id : azurerm_backup_policy_vm.main[each.value.backup_policy_name].id
  exclude_disk_luns   = each.value.exclude_disk_luns
  include_disk_luns   = each.value.include_disk_luns
  protection_state    = each.value.protection_state
}
