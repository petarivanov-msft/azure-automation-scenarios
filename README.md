# Azure Automation Demos - Complete Terraform Collection

A comprehensive collection of **4 production-ready Azure Automation scenarios** built with Terraform. Each scenario demonstrates different automation capabilities, from Microsoft Graph API integration to Hybrid Worker setups, with a focus on managed identities, infrastructure as code, and modern PowerShell practices.

## 🎯 Overview

This repository provides hands-on, deployable examples for learning Azure Automation concepts through Infrastructure as Code. Each scenario is self-contained, well-documented, and includes automated testing to verify functionality.

## 📦 What's Included

### Scenario 1: Graph API Automation with Managed Identity
**Directory**: `01-graph-api-automation/`  
**Difficulty**: Intermediate  
**Deploy Time**: ~5-7 minutes

Demonstrates Microsoft Graph API integration with Azure Automation using system-assigned managed identities. Automatically installs Graph SDK modules and configures API permissions to read users, groups, and applications.

**Key Features**:
- Microsoft Graph SDK v2.11.1 (Authentication, Users, Groups, Applications)
- Managed Identity with Microsoft Graph API permissions
- Automated permission grants via Microsoft Graph REST API
- Test runbook that retrieves users, groups, and applications

### Scenario 2: Start/Stop VMs with Tag-Based Scheduling
**Directory**: `02-startstop-vms/`  
**Difficulty**: Beginner  
**Deploy Time**: ~8-10 minutes

Automated VM power management based on PowerSchedule tags. Creates 3 Windows VMs with different schedules and automated start/stop runbooks with scheduling.

**Key Features**:
- 3 Windows Server 2022 VMs with PowerSchedule tags (AlwaysOn, BusinessHours, NightShutdown)
- Automated schedules (8 AM start, 6 PM stop Mon-Fri, 10 PM daily shutdown)
- Tag-based VM filtering and power management
- Cost optimization (up to 50% savings with scheduling)

### Scenario 3: PowerShell 7.4 Runtime Environment
**Directory**: `03-powershell74-runtime/`  
**Difficulty**: Advanced  
**Deploy Time**: ~6-8 minutes

Showcases PowerShell 7.4 features in Azure Automation including custom runtime environments, modern syntax, parallel processing, and enhanced cmdlets.

**Key Features**:
- PowerShell 7.4 runtime environment via REST API
- Modern PowerShell syntax (ternary operators, null coalescing, pipeline chaining)
- Parallel processing with ForEach-Object -Parallel
- 5 Az modules (Accounts 3.0.4, Compute 8.3.0, Storage 7.3.0, Resources 7.4.0, Monitor 5.2.1)
- 3 demo runbooks showcasing PS 7.4 capabilities

### Scenario 4: Hybrid Worker Lab Setup
**Directory**: `04-hybrid-worker-setup/`  
**Difficulty**: Intermediate  
**Deploy Time**: ~7-10 minutes

Complete Hybrid Worker environment with Windows VM, Hybrid Worker Extension, managed identities, and test runbook. Demonstrates running Azure Automation runbooks on machines outside Azure.

**Key Features**:
- Windows Server 2022 VM with Hybrid Worker Extension
- Hybrid Worker Group setup and registration
- System-assigned managed identities for VM and Automation Account
- PowerShell module deployment (Az.Accounts, Az.Compute)
- Test runbook with managed identity authentication
- Automated testing on deployment

## 🚀 Quick Start

### Deploy from Azure Cloud Shell (Recommended)

Azure Cloud Shell has Terraform and Azure CLI pre-installed, making deployment easy:

```bash
# 1. Open Azure Cloud Shell (PowerShell mode)
#    https://shell.azure.com

# 2. (Optional) Change subscription if needed
az account set --subscription "YOUR_SUBSCRIPTION_ID_OR_NAME"

# 3. Clone the repository
git clone https://github.com/petarivanov-msft/azure-automation-scenarios.git

# 4. Navigate to the repository
cd azure-automation-scenarios

# 5. Run the interactive deployment script
./deploy.ps1
```

**Note**: Cloud Shell automatically authenticates with your Azure subscription, so no `az login` is needed!

The interactive script provides:
- ✅ Interactive menu with scenario selection
- ✅ Prerequisite checking (Terraform, Azure CLI)
- ✅ Scenario details
- ✅ Automated Terraform init, plan, and apply
- ✅ Post-deployment summary with cleanup reminders
- ✅ Colorful, user-friendly interface

### Manual Deployment

For manual control, navigate to any scenario directory:

```powershell
# Navigate to desired scenario
cd 01-graph-api-automation

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply

# When done, cleanup
terraform destroy -auto-approve
```

### Cleanup Deployed Scenarios

Use the interactive cleanup script to destroy any deployed scenarios:

```powershell
.\destroy.ps1
```

The cleanup script provides:
- ✅ Automatic detection of deployed scenarios
- ✅ Interactive selection of scenarios to destroy
- ✅ Option to destroy all scenarios at once
- ✅ Confirmation prompts to prevent accidental deletion
- ✅ Automatic cleanup of local Terraform files

## 📋 Prerequisites

### Required Tools

- **Azure Subscription** - with appropriate permissions (Contributor role recommended)
- **Terraform** - Version >= 1.0 ([Download](https://www.terraform.io/downloads))
- **Azure CLI** - Latest version ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **PowerShell** - Version 7.0+ recommended (for deploy.ps1 script)

### Azure Permissions

Each scenario requires different permissions:

| Scenario | Required Permissions | Notes |
|----------|---------------------|-------|
| 1 - Graph API | **Privileged Administrator** or **Application Administrator** role in Entra ID | ⚠️ Requires elevated permissions to grant Graph API permissions |
| 2 - Start/Stop VMs | Contributor on resource group | ✅ Works with standard permissions |
| 3 - PowerShell 7.4 | Contributor on resource group | ✅ Works with standard permissions |
| 4 - Hybrid Worker | Contributor on subscription (for role assignments) | ✅ Works with standard permissions |

### Installation Verification

```powershell
# Check Terraform
terraform version

# Check Azure CLI
az version

# Check PowerShell
$PSVersionTable.PSVersion
```

## 📚 What You'll Learn

Across all scenarios, you'll gain hands-on experience with:

1. **Infrastructure as Code** - Terraform best practices and patterns
2. **Azure Automation** - Runbooks, modules, schedules, hybrid workers
3. **Managed Identities** - Secure authentication without credentials
4. **Microsoft Graph API** - Application permissions and API integration
5. **PowerShell Automation** - Modern PowerShell 7.4 features
6. **RBAC** - Role-based access control in Azure
7. **Cost Optimization** - VM scheduling and resource management
8. **Hybrid Cloud** - Running automation outside Azure
9. **REST APIs** - Azure REST API integration with Terraform
10. **Automated Testing** - Infrastructure validation patterns

## 🔧 Repository Structure

```
azure-automation-demos/
├── deploy.ps1                      # Interactive deployment script
├── destroy.ps1                     # Interactive cleanup script
├── common-functions.ps1            # Shared PowerShell functions
├── format-all.ps1                  # Terraform formatting utility
├── README.md                       # This file
├── LICENSE                         # MIT License
├── .gitignore                      # Git ignore patterns
├── .editorconfig                   # Editor configuration for consistent formatting
│
├── terraform-modules/              # Shared Terraform resources & docs
│   ├── README.md                   # Module documentation
│   └── common-variables/           # Reference implementations
│
├── 01-graph-api-automation/        # Scenario 1
│   ├── main.tf                     # Terraform configuration
│   ├── variables.tf                # Variable definitions
│   ├── outputs.tf                  # Output values
│   └── README.md                   # Scenario documentation
│
├── 02-startstop-vms/               # Scenario 2
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── 03-powershell74-runtime/        # Scenario 3
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── 04-hybrid-worker-setup/         # Scenario 4
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

## 🧪 Testing & Validation

Each scenario includes:

- **Automated Testing** - Resources deployed and tested during apply
- **Output Validation** - Comprehensive outputs with portal links
- **Test Commands** - Manual test commands in README files
- **Runbook Execution** - Automated or manual runbook testing

## 🔍 Troubleshooting

### Common Issues

**Issue**: Terraform initialization fails  
**Solution**: Ensure Terraform is installed and in PATH. Run `terraform version` to verify.

**Issue**: Azure CLI authentication errors  
**Solution**: Run `az login` and ensure you're logged into the correct subscription.

**Issue**: Insufficient permissions  
**Solution**: Verify you have Contributor role (or higher) on the subscription/resource group.

**Issue**: Module import fails in Automation Account  
**Solution**: Module imports can take 2-3 minutes. Wait for import to complete before running runbooks.

**Issue**: Hybrid Worker registration fails  
**Solution**: Check that AutomationHybridServiceUrl is correctly retrieved and VM has network connectivity.

**Issue**: PowerShell 7.4 runtime not showing  
**Solution**: Ensure runbook type is "PowerShell" (not "PowerShell72") and runtime environment is linked via PATCH API.

### Getting Help

- Check individual scenario README files for specific troubleshooting
- Review Terraform state: `terraform show`
- Check Azure Portal for resource status
- Review Automation Account job history for runbook errors

## 🎮 Advanced Usage

### Customization

Edit `variables.tf` in each scenario to customize:
- Azure region
- Resource naming prefixes
- VM sizes and configurations
- Module versions
- Tag values

### Multi-Environment Deployments

Use Terraform workspaces for multiple environments:

```powershell
# Create workspace
terraform workspace new dev

# Switch workspace
terraform workspace select prod

# List workspaces
terraform workspace list
```

### Integration with CI/CD

All scenarios support CI/CD integration:
- Use service principal authentication
- Store state in Azure Storage backend
- Implement approval gates for production

### Maintainer Tools

For contributors and maintainers, this repository includes several utility scripts:

```powershell
# Format all Terraform files
.\format-all.ps1

# Validate repository health
.\validate-repo.ps1
```

**Developer Resources**:
- `common-functions.ps1` - Shared PowerShell functions
- `.editorconfig` - Consistent formatting across editors
- `terraform-modules/` - Reference implementations
- [TOOLS.md](TOOLS.md) - Complete tool documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## ⚠️ Disclaimer

These scenarios are designed for **learning and demonstration purposes**. Review and test thoroughly before adapting for production use. Always follow your organization's security and compliance requirements.

## 📞 Support & Feedback

- **Issues**: Open an issue on GitHub
- **Discussions**: Start a discussion for questions or ideas
- **Documentation**: Each scenario includes detailed README

## 🎯 Next Steps

1. **Clone this repository**
   ```powershell
   git clone <repository-url>
   cd azure-automation-demos
   ```

2. **Run the interactive deployment script**
   ```powershell
   .\deploy.ps1
   ```

3. **Select a scenario** and follow the prompts

4. **Explore the deployed resources** in Azure Portal

5. **Remember to clean up** resources when done:
   ```powershell
   cd <scenario-directory>
   terraform destroy -auto-approve
   ```

---

**Package Version**: 1.0  
**Last Updated**: November 2025  
**Terraform Version**: >= 1.0  
**Provider Versions**: azurerm ~> 3.0, azapi ~> 1.0, azuread ~> 2.0

---

**Happy Automating! 🚀**
