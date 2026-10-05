# Assemble the per-secret sensitive variables into the name => value map the
# module expects. Hyphenated Key Vault secret names map to underscore variable
# names. Unset (null) variables are dropped so those secrets aren't managed.
locals {
  key_vault_secret_values = {
    for name, value in {
      "AppInsight-ConnectionString"      = var.AppInsight_ConnectionString
      "BPM-integration-GraphAPI-Secret"  = var.BPM_integration_GraphAPI_Secret
      "GemBox-License"                   = var.GemBox_License
      "Nocoly-API-Key"                   = var.Nocoly_API_Key
      "Nocoly-API-Sign"                  = var.Nocoly_API_Sign
      "Nocoly-Staff-Master-API-Key"      = var.Nocoly_Staff_Master_API_Key
      "Nocoly-Staff-Master-API-Sign"     = var.Nocoly_Staff_Master_API_Sign
      "Org-App-Key"                      = var.Org_App_Key
      "Org-App-Secret"                   = var.Org_App_Secret
      "Org-ID"                           = var.Org_ID
      "SharePoint-Client-ID"             = var.SharePoint_Client_ID
      "SharePoint-Client-Secret"         = var.SharePoint_Client_Secret
      "SharePoint-Tenant-ID"             = var.SharePoint_Tenant_ID
      "SMTP-Host"                        = var.SMTP_Host
      "SMTP-Password"                    = var.SMTP_Password
      "SMTP-User-Name"                   = var.SMTP_User_Name
      "SQL-connection-string-wk-account" = var.SQL_connection_string_wk_account
      "X-API-Key"                        = var.X_API_Key
    } : name => value if value != null
  }
}

module "bpm-uat" {
  source = "./modules"

  #Global Variable
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  #Resource Group
  resource_groups = var.resource_groups

  #Virtual Network
  virtual_networks = var.virtual_networks

  # Storage Account
  storage_accounts = var.storage_accounts

  # Private DNS Zone
  private_dns_zones = var.private_dns_zones

  # Windows Virtual Machines
  # windows_virtual_machines = var.windows_virtual_machines

  windows_virtual_machines_admin_username = var.windows_virtual_machines_admin_username
  windows_virtual_machines_admin_password = var.windows_virtual_machines_admin_password

  # Linux Virtual Machines
  linux_virtual_machines = var.linux_virtual_machines

  linux_virtual_machines_admin_username = var.linux_virtual_machines_admin_username
  linux_virtual_machines_admin_password = var.linux_virtual_machines_admin_password

  # Key Vault
  key_vaults              = var.key_vaults
  key_vault_secret_values = local.key_vault_secret_values

  # Application Gateway
  application_gateways              = var.application_gateways
  web_application_firewall_policies = var.web_application_firewall_policies

  # User Assign Identity
  user_assigned_identities = var.user_assigned_identities

  # Data Factory
  # data_factories = var.data_factories

  # SQL Server
  # mssql_servers                                = var.mssql_servers
  mssql_server_monitor_storage_subscription_id = var.mssql_server_monitor_storage_subscription_id

  mssql_servers_administrator_login          = var.mssql_servers_administrator_login
  mssql_servers_administrator_login_password = var.mssql_servers_administrator_login_password

  # MySQL Flexible Server
  mysql_flexible_servers                        = var.mysql_flexible_servers
  mysql_flexible_servers_administrator_login    = var.mysql_flexible_servers_administrator_login
  mysql_flexible_servers_administrator_password = var.mysql_flexible_servers_administrator_password

  # Azure Container Registry
  container_registries = var.container_registries

  # Azure Kubernetes Service
  kubernetes_clusters = var.kubernetes_clusters

  # Static Web Apps
  # static_web_apps = var.static_web_apps

  # Service Plan
  # service_plans = var.service_plans

  # Windows Web App
  # windows_web_apps = var.windows_web_apps

  # Windows Function App
  # windows_function_apps = var.windows_function_apps

  # Monitor Diagnostic Setting
  monitor_diagnostic_settings = var.monitor_diagnostic_settings

  # Front Door
  # cdn_frontdoor_profiles = var.cdn_frontdoor_profiles

  # Recovery Service Vault
  recovery_services_vaults = var.recovery_services_vaults

  # Monitor Activity Log Alert
  monitor_activity_log_alerts = var.monitor_activity_log_alerts

  # Action Group
  action_groups = var.action_groups

  # Security Center Email Notifications
  security_center_contacts = var.security_center_contacts

  # Public IP Address
  public_ips = var.public_ips

  # External Private Endpoints (e.g., MongoDB Atlas Private Link Service)
  mongo_private_endpoints = var.mongo_private_endpoints

  # VM Shutdown Schedule
  vm_shutdown_schedules = var.vm_shutdown_schedules

  # Automation Account
  # automation_accounts = var.automation_accounts

  # Budget Alert
  consumption_budget_subscription = var.consumption_budget_subscription

  # Log Analytics Workspace
  log_analytics_workspaces = var.log_analytics_workspaces

  # Backup for Blob Storage
  # data_protection_backup_vaults                 = var.data_protection_backup_vaults
  # data_protection_backup_policies_blob_storage  = var.data_protection_backup_policies_blob_storage
  data_protection_backup_instances_blob_storage = var.data_protection_backup_instances_blob_storage

  # Azure Monitor Workspace (Prometheus)
  monitor_workspaces = var.monitor_workspaces

  # Application Insights (workspace-based APM)
  application_insights = var.application_insights

  # Azure Managed Grafana
  dashboard_grafanas = var.dashboard_grafanas

  # Monitor Metric Alerts
  monitor_metric_alerts = var.monitor_metric_alerts

  # Monitor Scheduled Query Rules (Log Alerts v2)
  monitor_scheduled_query_rules = var.monitor_scheduled_query_rules

  # Linux VM Monitoring Agents (AMA + DCR)
  linux_vm_monitoring_agents = var.linux_vm_monitoring_agents
}
