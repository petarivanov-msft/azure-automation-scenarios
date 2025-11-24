# Azure Automation Scenarios Lab

A comprehensive Azure Automation lab environment built with Terraform, featuring four production-ready scenarios: Graph API automation, VM power management, PowerShell 7.4 runtime, and Hybrid Worker setup.

## 🚀 Quick Start (Recommended)

**The easiest way to deploy this lab is using Azure Portal Cloud Shell:**

### One-Liner Deployment

1. Open [Azure Portal](https://portal.azure.com)
2. Click on the **Cloud Shell** icon (terminal icon in the top menu)
3. Select **Bash** when prompted (first-time users)
4. Run this single command:

```bash
bash <(curl -s https://raw.githubusercontent.com/petarivanov-msft/azure-automation-scenarios/refs/heads/main/init-lab.sh)
```

### What You Get

This lab creates a comprehensive Azure Automation environment with:

- **Centralized Automation Account**: Single automation account with managed identity
- **Graph API Integration**: Microsoft Graph SDK with read permissions for users, groups, and applications
- **VM Power Management**: 3 test VMs with different power schedules (AlwaysOn, BusinessHours, NightShutdown)
- **PowerShell 7.4 Runtime**: Modern PowerShell features including parallel processing and ternary operators
- **Hybrid Worker**: Windows VM configured as Hybrid Worker with managed identity

### Deployment Details

- **Duration**: 15-25 minutes for complete setup
- **Interaction**: You'll be prompted for resource names, region, and scenario selection
- **Authentication**: Uses your current Azure Portal session (no separate login required)
- **Modular Design**: Enable/disable specific scenarios based on your needs

## 🏗️ Architecture

This lab demonstrates a unified Azure Automation environment:

### Core Infrastructure
- **Resource Group** with all resources
- **Azure Automation Account** with system-assigned managed identity
- **Virtual Network** with subnet for VMs
- **Network Security Group** with appropriate security rules

### Scenario 1: Graph API Automation
- **Modules**: Microsoft.Graph.Authentication, Users, Groups, Applications (v2.11.1)
- **Permissions**: User.Read.All, Group.Read.All, Application.Read.All, Directory.Read.All
- **Runbooks**: Get-UsersReport, Get-GroupsReport, Get-ApplicationsReport
- **Authentication**: Managed identity with Graph API permissions

### Scenario 2: Start/Stop VMs
- **VMs**: 3 Windows Server 2022 VMs with different power schedules
- **Tags**: PowerSchedule (AlwaysOn, BusinessHours, NightShutdown)
- **Runbooks**: Start-VMsByTag, Stop-VMsByTag, Get-VMPowerStateReport
- **RBAC**: Virtual Machine Contributor role for managed identity

### Scenario 3: PowerShell 7.4 Runtime
- **Runtime Environment**: PowerShell 7.4 with modern syntax support
- **Modules**: Az.Accounts 3.0.4, Az.Compute 8.3.0, Az.Storage 7.3.0, Az.Resources 7.4.0, Az.Monitor 5.2.1
- **Runbooks**: Demo-PowerShell74-Features, Demo-ParallelProcessing, Get-AzureResourceInventory
- **Features**: Ternary operators, null coalescing, parallel processing

### Scenario 4: Hybrid Worker
- **VM**: Windows Server 2022 with system-assigned managed identity
- **Extension**: HybridWorkerForWindows extension
- **Worker Group**: Hybrid Worker Group with VM registration
- **Runbook**: Test-HybridWorker-ManagedIdentity
- **RBAC**: Contributor role for VM and Automation Account identities

## 📋 Prerequisites

### For Cloud Shell Deployment (Recommended)
- Azure subscription with appropriate permissions
- No local software required - everything runs in Azure Cloud Shell!

### For Manual Deployment
- **Azure CLI** (latest version)
- **Terraform** >= 1.3.0
- **Git** for repository cloning
- **Bash Shell** (Linux/macOS/WSL)

### Azure Permissions

| Scenario | Required Permissions | Notes |
|----------|---------------------|-------|
| Graph API | **Privileged Administrator** or **Application Administrator** in Entra ID | ⚠️ Elevated permissions required |
| Start/Stop VMs | Contributor on resource group | ✅ Standard permissions |
| PowerShell 7.4 | Contributor on resource group | ✅ Standard permissions |
| Hybrid Worker | Contributor on subscription | ✅ Standard permissions |

## 🧹 Cleanup

### Cloud Shell Deployment

```bash
cd azure-automation-scenarios/terraform
terraform destroy -auto-approve
```

### Manual Deployment

```bash
cd terraform
terraform destroy -auto-approve
```

This will remove all deployed resources and avoid ongoing charges.

## 📖 Manual Deployment (Optional)

**Advanced users who prefer local development:**

### Prerequisites Check

```bash
# Check Terraform
terraform version

# Check Azure CLI
az version

# Login to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Deploy

```bash
# Clone repository
git clone https://github.com/petarivanov-msft/azure-automation-scenarios.git
cd azure-automation-scenarios/terraform

# Initialize Terraform
terraform init

# Create variables file
cat > terraform.tfvars <<EOF
resource_group_name     = "rg-automation-lab"
location                = "eastus"
automation_account_name = "auto-lab-12345"
vm_admin_username       = "azureadmin"
vm_admin_password       = "YourSecurePassword123!"

# Scenario toggles (true/false)
enable_graph_api       = true
enable_startstop_vms   = true
enable_powershell74    = true
enable_hybrid_worker   = true
EOF

# Review plan
terraform plan

# Deploy
terraform apply
```

## 🎮 Using the Lab

### View Deployed Resources

```bash
# Get all outputs
terraform output

# Get specific output
terraform output automation_account_name
terraform output automation_account_portal_url

# Get VM password (sensitive)
terraform output -raw vm_admin_password
```

### Execute Runbooks

#### Graph API Runbooks

```bash
# Get top 5 users
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Get-UsersReport" \
  --parameters '{"TopCount":5}'

# Get security groups
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Get-GroupsReport" \
  --parameters '{"TopCount":10,"GroupType":"Security"}'
```

#### VM Power Management

```bash
# Start BusinessHours VMs
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Start-VMsByTag" \
  --parameters '{"Schedule":"BusinessHours"}'

# Get VM power state report
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Get-VMPowerStateReport"
```

#### PowerShell 7.4 Demos

```bash
# Run PS 7.4 features demo
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Demo-PowerShell74-Features"

# Run parallel processing comparison
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Demo-ParallelProcessing"
```

#### Hybrid Worker Test

```bash
# Get worker group name
WORKER_GROUP=$(terraform output -raw hybrid_worker_group_name)

# Run test on Hybrid Worker
az automation runbook start \
  --automation-account-name $(terraform output -raw automation_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --name "Test-HybridWorker-ManagedIdentity" \
  --run-on "$WORKER_GROUP"
```

## 🔧 Customization

### Enable/Disable Scenarios

Edit `terraform.tfvars` to toggle scenarios:

```hcl
enable_graph_api       = true   # Set to false to skip
enable_startstop_vms   = true   # Set to false to skip
enable_powershell74    = true   # Set to false to skip
enable_hybrid_worker   = true   # Set to false to skip
```

### Change Azure Region

```hcl
location = "westus2"  # or any other Azure region
```

### Customize VM Settings

```hcl
vm_admin_username = "myadmin"
vm_admin_password = "MySecurePass123!"
```

## 🔍 Troubleshooting

### Common Issues

**Issue**: Graph API runbooks fail with "Insufficient privileges"  
**Solution**: Wait 5-10 minutes after deployment for permissions to propagate

**Issue**: Module import fails  
**Solution**: Modules can take 2-3 minutes to import. Check Automation Account → Modules → verify status is "Available"

**Issue**: Hybrid Worker registration fails  
**Solution**: Check VM has network connectivity and extension is installed properly

**Issue**: PowerShell 7.4 runtime not showing  
**Solution**: Runtime environment requires Azure CLI REST API. Ensure proper authentication.

### Getting Help

- Check individual runbook job history in Azure Portal
- Review Terraform state: `terraform show`
- Check Azure Activity Log for deployment errors
- Review NSG rules if VMs are not accessible

## 📚 What You'll Learn

1. **Infrastructure as Code**: Terraform best practices with modular design
2. **Azure Automation**: Runbooks, modules, schedules, and Hybrid Workers
3. **Managed Identities**: Secure authentication without credentials
4. **Microsoft Graph API**: Application permissions and API integration
5. **PowerShell Automation**: Modern PowerShell 7.4 features
6. **RBAC**: Role-based access control in Azure
7. **Cost Optimization**: VM scheduling and resource management
8. **Hybrid Cloud**: Running automation outside Azure

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with a clear description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔒 Security

Please review our [SECURITY.md](SECURITY.md) for reporting security vulnerabilities.

## ⚠️ Disclaimer

This lab is designed for **learning and demonstration purposes**. Review and test thoroughly before adapting for production use. Always follow your organization's security and compliance requirements.

## 📞 Support & Issues

- **Documentation**: Check this README and module-specific documentation
- **Issues**: Open an issue in this GitHub repository
- **Questions**: Review the troubleshooting section above

---

**Last Updated**: November 2024  
**Terraform Version**: >= 1.3.0  
**Provider Versions**: azurerm ~> 3.0, azuread ~> 2.0, azapi ~> 1.0

---

**Happy Automating! 🚀**
