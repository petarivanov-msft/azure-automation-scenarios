# Azure Automation - Hybrid Worker Lab

## 📖 Overview

This scenario demonstrates how to set up an **Azure Automation Hybrid Worker** environment using Terraform. Hybrid Workers allow you to run automation runbooks on machines outside of Azure, such as on-premises servers or VMs in other clouds.

## 🎯 What This Scenario Deploys

- ✅ **Windows VM** (Windows Server 2022) with system-assigned managed identity
- ✅ **Azure Automation Account** with system-assigned managed identity
- ✅ **Hybrid Worker Group** and VM registration
- ✅ **PowerShell Modules** (Az.Accounts, Az.Compute) on both VM and Automation Account
- ✅ **Test Runbook** that uses managed identity authentication
- ✅ **Automated Testing** - Runbook execution on deployment
- ✅ **RBAC** - Contributor role assignments for both managed identities

## 🏗️ Architecture

```
Azure Subscription
└── Resource Group
    ├── Automation Account (with managed identity)
    │   ├── Hybrid Worker Group
    │   ├── PowerShell Modules (Az.Accounts, Az.Compute)
    │   └── Test Runbook
    ├── Windows VM (with managed identity)
    │   ├── Hybrid Worker Extension
    │   └── PowerShell Modules
    └── Virtual Network
        └── Subnet + NSG + Public IP
```

## 📋 Prerequisites

- Azure subscription
- Azure CLI or PowerShell Az module installed
- Terraform >= 1.0
- Appropriate Azure permissions (Contributor role recommended)

## 🚀 Deployment

### 1. Navigate to Scenario Directory

```powershell
cd 04-hybrid-worker-setup
```

### 2. Initialize Terraform

```powershell
terraform init
```

### 3. Review the Plan

```powershell
terraform plan
```

### 4. Deploy

```powershell
terraform apply
```

Deployment takes approximately **7-10 minutes**.

## 📊 What You'll See

After deployment completes, Terraform will output:

- Resource Group name and portal link
- Automation Account name and portal link
- VM details (name, public IP, size)
- Hybrid Worker Group name
- Test Runbook name and portal link
- VM credentials (username shown, password requires separate command)
- Azure Portal links to all resources
- Test commands for manual runbook execution

## 🧪 Testing

### View the Automated Test Results

The test runbook automatically runs during deployment. Check the output for:
- Azure connection success via managed identity
- List of VMs in the subscription
- Details about the Hybrid Worker VM itself

### Manual Runbook Execution

#### Option 1: Azure CLI

```bash
az automation runbook start \
  --automation-account-name <automation-account-name> \
  --resource-group <resource-group-name> \
  --name Test-HybridWorker-ManagedIdentity \
  --run-on <worker-group-name>
```

#### Option 2: PowerShell

```powershell
Start-AzAutomationRunbook `
  -AutomationAccountName <automation-account-name> `
  -ResourceGroupName <resource-group-name> `
  -Name "Test-HybridWorker-ManagedIdentity" `
  -RunOn <worker-group-name>
```

#### Option 3: Azure Portal

Use the `runbook_link` output to open the runbook directly in Azure Portal and click **Start**.

## 🔍 What the Test Runbook Does

The test runbook demonstrates key Hybrid Worker capabilities:

1. **Connects to Azure** using the VM's system-assigned managed identity
2. **Lists all VMs** in the subscription
3. **Retrieves details** about the Hybrid Worker VM itself
4. **Shows installed extensions** on the VM

## 🎓 Key Learning Points

1. **Infrastructure as Code** - Complete Hybrid Worker setup via Terraform
2. **Managed Identities** - Secure authentication without storing credentials
3. **Hybrid Workers** - Run Azure Automation outside Azure regions
4. **PowerShell Automation** - Az module usage in runbooks
5. **RBAC** - Proper role assignment for automation accounts
6. **External Data Sources** - Terraform integration with Azure REST API
7. **Automated Testing** - Infrastructure validation through runbook execution

## ⚙️ Customization

Edit `variables.tf` to customize:

- **Azure Region**: Default is `East US`
- **Resource Prefix**: Default is `hwlab`
- **VM Size**: Default is `Standard_B2s`
- **Admin Username**: Default is `azureadmin`
- **Auto-test Runbook**: Default is `true`

## 🔧 Troubleshooting

### Common Issues

1. **AutomationHybridServiceUrl Errors**
   - The configuration uses PowerShell for cross-platform compatibility
   - Fallback to "placeholder" value on error
   - Extension will update URL automatically

2. **Hybrid Worker Registration**
   - Worker is registered before extension installation
   - Proper dependency chain ensures correct order

3. **Module Installation Delays**
   - Az.Compute depends on Az.Accounts
   - Modules may take 2-3 minutes to import

4. **Runbook Execution Timeout**
   - Default wait time is 2 minutes
   - Increase if needed for larger subscriptions

## 🎮 Next Steps

1. **Create Custom Runbooks** - Automate VM management, backups, monitoring
2. **Connect On-Premises** - Install Hybrid Worker on on-prem servers
3. **Integrate Monitoring** - Send logs to Azure Monitor or Log Analytics
4. **Multi-Environment** - Use Terraform workspaces for dev/test/prod
5. **Schedule Runbooks** - Add automated schedules for recurring tasks

## 🧹 Cleanup

To destroy all resources and avoid charges:

```powershell
terraform destroy -auto-approve
```

This will remove:
- Virtual Machine
- Automation Account
- Hybrid Worker Group
- Network resources
- All associated configurations

## 📚 Additional Resources

- [Azure Automation Hybrid Worker Documentation](https://learn.microsoft.com/azure/automation/automation-hybrid-runbook-worker)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Automation Best Practices](https://learn.microsoft.com/azure/automation/automation-intro)
- [PowerShell Az Module](https://learn.microsoft.com/powershell/azure/)

## 📄 License

MIT License - See main repository LICENSE file for details.

## ⚠️ Disclaimer

This is a **lab/demo configuration** for learning purposes. Review and test thoroughly before using in production environments.

---

**Scenario**: 4 of 4  
**Difficulty**: Intermediate  
**Time to Deploy**: ~7-10 minutes  
**Learning Value**: ⭐⭐⭐⭐⭐

Made with ❤️ for Azure Automation learners
