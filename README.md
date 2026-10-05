# BPM Azure Terraform - UAT Environment

This repository contains Terraform configurations for provisioning and managing Azure infrastructure for the BPM UAT (User Acceptance Testing) environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Resources Managed](#resources-managed)
- [Usage](#usage)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Variables](#variables)
- [Outputs](#outputs)
- [Notes](#notes)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Azure subscription with appropriate permissions
- Service Principal or Managed Identity with required access

## Project Structure

```
.
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── uat.terraform.auto.tfvars   # UAT environment variable values
├── modules/                     # Terraform modules directory
└── README.md                    # This file
```

## Resources Managed

This Terraform configuration manages the following Azure resources:

- **Resource Groups** - Container for Azure resources
- **Virtual Networks** - Network infrastructure and subnets
- **Storage Accounts** - Blob, file, and table storage
- **Private DNS Zones** - Private DNS resolution
- **Windows Virtual Machines** - Compute instances
- **Key Vaults** - Secrets and certificate management
- **Application Gateways** - Load balancing and web traffic management
- **User Assigned Identities** - Managed identities
- **Data Factory** - Data integration and ETL pipelines
- **SQL Servers** - Database instances
- **Static Web Apps** - Static website hosting
- **App Service Plans** - Web app hosting plans
- **Windows Web Apps** - Web application hosting
- **Windows Function Apps** - Serverless compute
- **Monitor Diagnostic Settings** - Logging and diagnostics
- **Front Door (CDN)** - Content delivery and global load balancing
- **Recovery Services Vaults** - Backup and disaster recovery
- **Monitor Activity Log Alerts** - Activity monitoring and alerts
- **Action Groups** - Notification and action automation
- **Security Center Contacts** - Security notifications
- **Public IP Addresses** - Public internet connectivity
- **VM Shutdown Schedules** - Automated VM shutdown/startup
- **Automation Accounts** - Process automation
- **Consumption Budgets** - Cost management and alerts
- **Log Analytics Workspaces** - Log aggregation and analysis
- **Data Protection Backup Vaults** - Backup management
- **Backup Policies** - Backup configuration for blob storage
- **Backup Instances** - Backup instances for blob storage

## Usage

### Authentication

Login to Azure using Azure CLI:

```bash
az login
az account set --subscription "<subscription-id>"
```

### Initialize Terraform

Initialize the Terraform working directory:

```bash
terraform init
```

### Plan

Review the execution plan:

```bash
terraform plan
```

### Apply

Apply the Terraform configuration:

```bash
terraform apply
```

### Destroy

Destroy the infrastructure (use with caution):

```bash
terraform destroy
```

## Configuration

### Required Variables

The following variables must be configured in `uat.terraform.auto.tfvars`:

- `tenant_id` - Azure AD Tenant ID
- `subscription_id` - Azure Subscription ID
- `resource_groups` - Resource group configurations
- `virtual_networks` - Virtual network configurations
- `storage_accounts` - Storage account configurations
- (See `variables.tf` for complete list)

### Sensitive Variables

Sensitive variables such as passwords and secrets should be:
- Stored securely (e.g., Azure Key Vault, environment variables)
- Never committed to version control
- Passed via secure methods during deployment

Sensitive variables include:
- `windows_virtual_machines_admin_username`
- `windows_virtual_machines_admin_password`
- `mssql_servers_administrator_login`
- `mssql_servers_administrator_login_password`

## Deployment

### Standard Deployment

1. Ensure prerequisites are met
2. Configure variables in `uat.terraform.auto.tfvars`
3. Initialize Terraform: `terraform init`
4. Review changes: `terraform plan`
5. Apply changes: `terraform apply`
6. Confirm when prompted

### CI/CD Pipeline

For automated deployments:
1. Use service principal authentication
2. Store sensitive variables in pipeline secrets
3. Implement state locking with Azure Storage
4. Use terraform workspaces for environment isolation

## Variables

All variables are defined in `variables.tf`. Values for the UAT environment are specified in `uat.terraform.auto.tfvars`.

Key variable categories:
- Global settings (tenant, subscription)
- Resource configurations (per resource type)
- Network settings
- Security settings
- Monitoring and logging settings

## Outputs

Outputs are defined in the module and can be referenced after successful deployment using:

```bash
terraform output
```

## Notes

- Always review the execution plan before applying changes
- Maintain separate state files for different environments
- Use remote state backend for team collaboration
- Follow Azure naming conventions and tagging standards
- Regularly review and update security configurations
- Monitor costs and set up appropriate budget alerts
- Keep Terraform and provider versions up to date
- Back up important data before making infrastructure changes

## MongoDB Atlas Private Link Configuration

This section documents the MongoDB Atlas Private Link setup for secure, private connectivity between Azure resources and MongoDB Atlas in the UAT environment.

### Overview

MongoDB Atlas Private Link enables private connectivity from Azure VNet to MongoDB Atlas clusters without traversing the public internet. All traffic flows through Azure backbone network via Private Endpoint.

### Azure Resources

#### Private Endpoint
- **Name**: `BPM-UAT-MONGO-PE-01`
- **Resource Group**: `BPM-UAT-RG`
- **Location**: `East Asia`
- **Subnet**: `BPM-UAT-PE-SUBNET-01` (in `BPM-UAT-VNET-01`)
- **Private IP**: `10.128.58.73`
- **Connection Type**: Manual (requires approval)
- **Connection State**: Approved

#### Private DNS Zone
- **Zone Name**: `privatelink.mongodb.net`
- **Resource Group**: `BPM-UAT-RG`
- **VNet Link**: `BPM-UAT-VNET-01` (registration disabled)

#### DNS A Records
The following A records map MongoDB Atlas replica set hostnames to the private endpoint IP:

| Hostname | Type | TTL | IP Address |
|----------|------|-----|------------|
| `ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net` | A | 300 | 10.128.58.73 |
| `ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net` | A | 300 | 10.128.58.73 |
| `ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net` | A | 300 | 10.128.58.73 |

### MongoDB Atlas Configuration

#### Project Details
- **Project Name**: `BPM-UAT`
- **Project ID**: `698b00bb38d822faa4b43211`
- **Organization ID**: `698b00bb38d822faa4b43187`

#### Cluster Details
- **Cluster Name**: `ccg-bpm-uat-mongo`
- **Cluster ID**: `698e91f95832f6a0357a5ea3`
- **MongoDB Version**: `8.0.19`
- **Tier**: `M10` (with autoscaling to M20)
- **Region**: `ASIA_EAST` (Azure East Asia)
- **Provider**: Azure
- **Replication**: 3-node replica set
- **Backup**: Enabled (Point-in-Time enabled)

#### Private Link Service
- **Endpoint Service ID**: `698e97668a76ad948a99a20f`
- **Status**: `AVAILABLE`
- **Private Link Service Name**: `pls_698e97668a76ad948a99a20f`
- **Resource ID**: `/subscriptions/963d0d29-ad7a-48ae-8091-62149f04a566/resourceGroups/rg_698e91f95832f6a0357a5ef1_psg02le5/providers/Microsoft.Network/privateLinkServices/pls_698e97668a76ad948a99a20f`

#### Azure Private Endpoint Interface
- **Status**: `AVAILABLE`
- **Private Endpoint Connection Name**: `e795b910-68e2-484a-92b5-02bd7ca2d517/BPM-UAT-RG/BPM-UAT-MONGO-PE-01`
- **Private Endpoint IP**: `10.128.58.73`
- **Azure Resource ID**: `/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Network/privateEndpoints/BPM-UAT-MONGO-PE-01`

### Connection Strings

#### Standard (Non-SRV) Connection String
```
mongodb://ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-12yu5j-shard-0
```

#### SRV Connection String
```
mongodb+srv://ccg-bpm-uat-mongo.bkgz1dq.mongodb.net
```

**Note**: Both connection strings will resolve to private IPs (`10.128.58.73`) when accessed from resources within `BPM-UAT-VNET-01` (VM, AKS pods).

### Connectivity Access

The following Azure resources can connect to MongoDB Atlas via Private Link:

1. **Virtual Machines**
   - `BPM-UAT-MIDDLEWARE-VM-01` (10.128.58.132)
   - `BPM-UAT-JUMP-VM-01`
   - `BPM-UAT-DGW-VM-01`
   - `BPM-ADF-UAT-SHIR-VM-01`

2. **Azure Kubernetes Service**
   - `BPM-UAT-AKS-01` (private cluster)
   - All pods in the cluster can connect via private DNS resolution

3. **Other Services**
   - Azure Data Factory
   - App Services with VNet integration
   - Function Apps with VNet integration

### Verification Steps

#### From Virtual Machine

SSH to any VM in `BPM-UAT-VNET-01`:

```bash
# Test DNS resolution
nslookup ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net
# Expected: Should resolve to 10.128.58.73

# Test TCP connectivity
nc -zv ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net 27017
nc -zv ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net 27017
nc -zv ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net 27017
# Expected: All should show "succeeded"

# Test MongoDB connection (with mongosh installed)
mongosh "mongodb://ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-12yu5j-shard-0" --username <user> --password <pass>
```

#### From AKS Pod

```bash
# Create a debug pod with MongoDB client
kubectl run -it --rm mongo-test --image=mongo:latest --restart=Never -- sh

# Inside the pod, test DNS
nslookup ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net
# Expected: Should resolve to 10.128.58.73

# Test connection
mongosh "mongodb://ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-12yu5j-shard-0" --username <user> --password <pass>
```

#### Verify Private Link Traffic

Check that traffic is flowing through private endpoint:

```bash
# From Azure Portal
# Navigate to: BPM-UAT-MONGO-PE-01 → Metrics → "Bytes Sent" and "Bytes Received"
# Should show traffic when applications are connecting

# From Atlas Dashboard
# Navigate to: Cluster → Metrics → Network
# Should show connections coming from Azure Private Link region
```

### Troubleshooting

#### DNS Not Resolving to Private IP

If hostnames resolve to public IPs instead of `10.128.58.73`:

1. Verify VNet link exists:
   ```bash
   az network private-dns link vnet show -g BPM-UAT-RG -z privatelink.mongodb.net -n BPM-UAT-VNET-01-LINK
   ```

2. Check A records exist:
   ```bash
   az network private-dns record-set a list -g BPM-UAT-RG -z privatelink.mongodb.net -o table
   ```

3. Check from VM if DNS is resolving correctly:
   ```bash
   dig ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net
   ```

#### Connection Timeout

If connection times out:

1. Verify NSG rules allow outbound to private endpoint subnet
2. Check route tables don't block traffic to `10.128.58.0/24`
3. Verify Atlas interface status is `AVAILABLE`:
   ```bash
   atlas privateEndpoints azure interfaces describe "<PE_ID>" \
     --endpointServiceId 698e97668a76ad948a99a20f \
     --projectId 698b00bb38d822faa4b43211
   ```

#### Atlas Interface Commands

Using MongoDB Atlas CLI with API keys:

```bash
# Set credentials as environment variables
export MONGODB_ATLAS_PUBLIC_API_KEY='fhkqxmld'
export MONGODB_ATLAS_PRIVATE_API_KEY='17f10b01-d608-4568-b4e0-b8e59902a33d'

# List all private endpoints
atlas privateEndpoints azure list --projectId 698b00bb38d822faa4b43211

# Describe interface
atlas privateEndpoints azure interfaces describe \
  "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Network/privateEndpoints/BPM-UAT-MONGO-PE-01" \
  --endpointServiceId 698e97668a76ad948a99a20f \
  --projectId 698b00bb38d822faa4b43211
```

### Security Considerations

1. **Network Isolation**: All MongoDB traffic flows through private endpoint, never traversing public internet
2. **Authentication**: Standard MongoDB authentication required (username/password or certificates)
3. **Encryption**: TLS/SSL enabled for all connections (`ssl=true` in connection string)
4. **Access Control**: Only resources in `BPM-UAT-VNET-01` can resolve private hostnames
5. **Manual Approval**: Private endpoint connection requires manual approval in Atlas (already approved)

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│  BPM-UAT-VNET-01 (10.128.0.0/16)                       │
│                                                         │
│  ┌──────────────────────────────────┐                  │
│  │ BPM-UAT-PE-SUBNET-01             │                  │
│  │ (10.128.58.0/24)                 │                  │
│  │                                   │                  │
│  │  ┌────────────────────────────┐  │                  │
│  │  │ BPM-UAT-MONGO-PE-01        │  │                  │
│  │  │ IP: 10.128.58.73           │──┼──────────────┐   │
│  │  └────────────────────────────┘  │              │   │
│  └──────────────────────────────────┘              │   │
│                                                     │   │
│  ┌──────────────────────────────────┐              │   │
│  │ BPM-UAT-AKS-01                   │              │   │
│  │ (Private AKS Cluster)            │              │   │
│  │                                  │              │   │
│  │  Pods resolve:                   │              │   │
│  │  *.bkgz1dq.mongodb.net          │              │   │
│  │    → 10.128.58.73               │              │   │
│  └──────────────────────────────────┘              │   │
│                                                     │   │
│  ┌──────────────────────────────────┐              │   │
│  │ BPM-UAT-MIDDLEWARE-VM-01         │              │   │
│  │ (10.128.58.132)                  │              │   │
│  │                                  │              │   │
│  │  DNS resolves:                   │              │   │
│  │  *.bkgz1dq.mongodb.net          │              │   │
│  │    → 10.128.58.73               │              │   │
│  └──────────────────────────────────┘              │   │
│                                                     │   │
│  Private DNS Zone: privatelink.mongodb.net         │   │
└─────────────────────────────────────────────────────┘   │
                                                          │
                      Azure Private Link                  │
                      (Over Microsoft Backbone)           │
                                                          │
┌─────────────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │ MongoDB Atlas (Atlas Subscription)               │
│  │                                                  │
│  │  Private Link Service:                          │
│  │  pls_698e97668a76ad948a99a20f                  │
│  │                                                  │
│  │  ┌────────────────────────────────────────┐    │
│  │  │ Cluster: ccg-bpm-uat-mongo             │    │
│  │  │ Tier: M10 (autoscale to M20)           │    │
│  │  │ MongoDB 8.0.19                          │    │
│  │  │                                         │    │
│  │  │ Replica Set:                            │    │
│  │  │  - ac-pryqln5-shard-00-00.bkgz1dq     │    │
│  │  │  - ac-pryqln5-shard-00-01.bkgz1dq     │    │
│  │  │  - ac-pryqln5-shard-00-02.bkgz1dq     │    │
│  │  └────────────────────────────────────────┘    │
│  └──────────────────────────────────────────────────┘
└────────────────────────────────────────────────────────
```

### Configuration Files

The MongoDB Atlas Private Link configuration spans multiple files:

- **`uat.terraform.auto.tfvars`**:
  - `mongo_private_endpoints` - Private endpoint definition
  - `private_dns_zones` - DNS zone and A records for `privatelink.mongodb.net`

- **`modules/az-private-endpoint-manual.tf`**:
  - Generic module for manual private endpoints (resource ID/alias mode)
  - Supports `is_manual_connection = true` for approval-based connections

### Initial Setup Steps (Already Completed)

1. **Create Atlas Private Link Service** (in Atlas Console)
   - Region: Asia East (matches Azure East Asia)
   - Generated Private Link Service ID

2. **Create Azure Private Endpoint** (via Terraform)
   ```hcl
   mongo_private_endpoints = [
     {
       name                           = "BPM-UAT-MONGO-PE-01"
       private_connection_resource_id = "/subscriptions/.../pls_698e97668a76ad948a99a20f"
       is_manual_connection           = true
       request_message                = "Private endpoint connection request..."
     }
   ]
   ```

3. **Register Azure PE with Atlas** (via Atlas CLI)
   ```bash
   atlas privateEndpoints azure interfaces create <endpointServiceId> \
     --projectId 698b00bb38d822faa4b43211 \
     --privateEndpointId "<Azure-PE-Resource-ID>" \
     --privateEndpointIpAddress "10.128.58.73"
   ```

4. **Approve Connection** (in Atlas Console or auto-approved)
   - Connection state changed to `Approved`

5. **Create DNS Records** (via Terraform)
   - Added A records mapping replica set hostnames to PE IP

### Connection Testing

#### Test DNS Resolution
```bash
# From VM or AKS pod
nslookup ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net
# Should return: 10.128.58.73

nslookup ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net
# Should return: 10.128.58.73

nslookup ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net
# Should return: 10.128.58.73
```

#### Test TCP Connectivity
```bash
nc -zv ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net 27017
nc -zv ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net 27017
nc -zv ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net 27017
# All should show "succeeded"
```

#### Test MongoDB Connection
```bash
# Using mongosh
mongosh "mongodb://ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-12yu5j-shard-0" \
  --username <your-username> \
  --password <your-password>

# Or using connection string in application
# Replace <user>:<pass> with actual credentials:
mongodb://<user>:<pass>@ac-pryqln5-shard-00-00.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-01.bkgz1dq.mongodb.net:27017,ac-pryqln5-shard-00-02.bkgz1dq.mongodb.net:27017/?ssl=true&authSource=admin&replicaSet=atlas-12yu5j-shard-0
```

### Management and Monitoring

#### Atlas CLI Commands

Set up environment variables:
```bash
export MONGODB_ATLAS_PUBLIC_API_KEY='fhkqxmld'
export MONGODB_ATLAS_PRIVATE_API_KEY='17f10b01-d608-4568-b4e0-b8e59902a33d'
```

Useful commands:
```bash
# List projects
atlas projects list

# List clusters
atlas clusters list --projectId 698b00bb38d822faa4b43211

# Get cluster details
atlas clusters describe ccg-bpm-uat-mongo --projectId 698b00bb38d822faa4b43211

# List private endpoints
atlas privateEndpoints azure list --projectId 698b00bb38d822faa4b43211

# Describe interface
atlas privateEndpoints azure interfaces describe \
  "/subscriptions/e795b910-68e2-484a-92b5-02bd7ca2d517/resourceGroups/BPM-UAT-RG/providers/Microsoft.Network/privateEndpoints/BPM-UAT-MONGO-PE-01" \
  --endpointServiceId 698e97668a76ad948a99a20f \
  --projectId 698b00bb38d822faa4b43211
```

#### Azure CLI Commands

```bash
# Set subscription
az account set --subscription e795b910-68e2-484a-92b5-02bd7ca2d517

# Check private endpoint status
az network private-endpoint show -g BPM-UAT-RG -n BPM-UAT-MONGO-PE-01

# Check private DNS zone
az network private-dns zone show -g BPM-UAT-RG -n privatelink.mongodb.net

# List DNS A records
az network private-dns record-set a list -g BPM-UAT-RG -z privatelink.mongodb.net -o table

# Check VNet link
az network private-dns link vnet show -g BPM-UAT-RG -z privatelink.mongodb.net -n BPM-UAT-VNET-01-LINK
```

### Important Notes

1. **Private Link Service Subscription**: The Atlas Private Link Service resides in a MongoDB-managed Azure subscription (`963d0d29-ad7a-48ae-8091-62149f04a566`)
2. **Manual Approval Required**: Initial connection requires approval (already approved for `BPM-UAT-MONGO-PE-01`)
3. **DNS Resolution Required**: Applications must use the hostnames from connection strings, not IPs directly
4. **All Replica Set Members**: All three MongoDB replica set members resolve to the same private endpoint IP
5. **SSL Required**: All connections must use SSL/TLS (`ssl=true` parameter)
6. **No Public Access**: With Private Link, cluster can disable public endpoint access in Atlas for enhanced security

### Cost Implications

- **Azure Private Endpoint**: ~$7.30/month (charged per endpoint)
- **Data Transfer**: Inbound to private endpoint is free; outbound charged at standard Azure rates
- **MongoDB Atlas**: Standard Atlas cluster costs (M10 tier with autoscaling)

## Support

For issues or questions related to this infrastructure configuration, please contact the infrastructure team.

# Route manually deleted from BPM-UAT-AGW-RT-01 to fix AGW V2 compatibility
#   c h i n a c h a m - t e r r a f o r m  
 