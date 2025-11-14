# Azure Automation - Microsoft Graph API Automation

Real-world Azure Automation scenario using Microsoft Graph PowerShell SDK with managed identity to query users, groups, and applications from Azure AD/Entra ID.

## 🎯 What This Does

Creates a production-ready Graph API automation environment with:
- ✅ Azure Automation Account with managed identity
- ✅ Microsoft.Graph PowerShell modules installed
- ✅ **Managed identity with Microsoft Graph API permissions** (no app registration needed!)
- ✅ Runbooks to query users, groups, and app registrations
- ✅ Real Microsoft Graph API calls using `Connect-MgGraph -Identity`
- ✅ Automated testing with live Graph queries
- ✅ RBAC permissions: User.Read.All, Group.Read.All, Application.Read.All, Directory.Read.All

## 🚀 Quick Start (Azure Cloud Shell)

### 1. Open Azure Cloud Shell
```bash
# Go to: https://shell.azure.com
# Choose Bash when prompted
```

### 2. Verify your subscription
```bash
az account show
az account set --subscription "YOUR_SUBSCRIPTION_ID_OR_NAME"
```

### 3. Clone and deploy
```bash
git clone https://github.com/petarivanov-msft/azure-automation-demos.git
cd azure-automation-demos/01-graph-api-automation

# Deploy
terraform init
terraform apply -auto-approve
```

### 4. View Results
After deployment (~10 minutes), you'll see outputs with portal links and the test runbook execution results.

### 5. Cleanup
```bash
terraform destroy -auto-approve
```

## 📦 What's Included

- **`main.tf`** - Complete infrastructure with Graph API permissions
- **`variables.tf`** - Customizable parameters
- **`outputs.tf`** - Portal links and resource information
- **`README.md`** - This file
- **`QUICKSTART.md`** - Copy-paste commands
- **`GUIDE.md`** - Comprehensive guide

## 📜 Runbooks

### 1. Get-UsersReport
Queries users from Microsoft Graph API using managed identity.

**Parameters**:
- `TopCount` (int): Number of users to retrieve (default: 10)

**Graph Permission**: User.Read.All

**Example Output**:
```
Display Name: John Doe
UPN: john.doe@contoso.com
Email: john.doe@contoso.com
Account Enabled: True
User Type: Member
Created: 2024-01-15T10:30:00Z
```

### 2. Get-GroupsReport
Queries groups from Microsoft Graph API.

**Parameters**:
- `TopCount` (int): Number of groups to retrieve (default: 10)
- `GroupType` (string): Filter by type - All, Security, Microsoft365 (default: All)

**Graph Permission**: Group.Read.All

**Example Output**:
```
Group Name: IT Administrators
Type: Security Group
Security Enabled: True
Mail Enabled: False
Members: 15
Created: 2023-05-20T08:15:00Z
```

### 3. Get-ApplicationsReport
Queries application registrations from Microsoft Graph API.

**Parameters**:
- `TopCount` (int): Number of applications to retrieve (default: 10)

**Graph Permission**: Application.Read.All

## 🔑 Microsoft Graph Permissions

This demo grants the following **application permissions** to the managed identity:

| Permission | ID | Purpose |
|-----------|-----|---------|
| User.Read.All | df021288-bdef-4463-88db-98f22de89214 | Read all users in the directory |
| Group.Read.All | 5b567255-7703-4780-807c-7be8301ae99b | Read all groups in the directory |
| Application.Read.All | 9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30 | Read all applications |
| Directory.Read.All | 7ab1d382-f21e-4acd-a863-ba3e13f7da61 | Read directory data |

**Note**: These are READ-ONLY permissions. No write operations are possible.

## 🎮 Usage Examples

### Execute Runbooks Manually

```bash
# Get automation account details
AUTOMATION_ACCOUNT=$(terraform output -raw automation_account_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Query top 5 users
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Get-UsersReport" \
  --parameters '{"TopCount":5}'

# Query security groups only
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Get-GroupsReport" \
  --parameters '{"TopCount":10,"GroupType":"Security"}'

# Query applications
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Get-ApplicationsReport" \
  --parameters '{"TopCount":10}'
```

### View Job Output

```bash
# List recent jobs
az automation job list \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --output table

# Get specific job output
JOB_ID="<job-id-from-above>"
az automation job output show \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --job-name "$JOB_ID"
```

## 📚 What You'll Learn

1. Azure Automation with managed identities
2. Microsoft Graph PowerShell SDK
3. Granting Graph API permissions to managed identities
4. Using `Connect-MgGraph -Identity` in runbooks
5. Querying users, groups, and applications from Azure AD
6. Infrastructure as Code with Terraform
7. Azure AD app role assignments

## 🔧 How It Works

### Architecture
```
Azure Subscription
└── Resource Group
    └── Automation Account (Managed Identity)
        ├── Identity granted Graph API permissions:
        │   ├── User.Read.All
        │   ├── Group.Read.All
        │   ├── Application.Read.All
        │   └── Directory.Read.All
        │
        ├── PowerShell Modules:
        │   ├── Microsoft.Graph.Authentication
        │   ├── Microsoft.Graph.Users
        │   ├── Microsoft.Graph.Groups
        │   └── Microsoft.Graph.Applications
        │
        └── Runbooks:
            ├── Get-UsersReport
            ├── Get-GroupsReport
            └── Get-ApplicationsReport
```

### Authentication Flow

1. Runbook calls `Connect-MgGraph -Identity`
2. Automation Account's managed identity authenticates to Azure AD
3. Azure AD checks granted permissions
4. Microsoft Graph API returns requested data
5. Runbook processes and outputs data

### Key Benefits

- **No credentials to manage** - Managed identity handles authentication
- **No app registration needed** - Uses system-assigned identity
- **Automatic token management** - Graph SDK handles token refresh
- **Secure** - No secrets stored in code or variables

## 🔍 Troubleshooting

### Runbook fails with "Insufficient privileges"
- Wait 5-10 minutes after deployment for permissions to propagate
- Verify permissions: Check Enterprise Applications in Azure AD for the managed identity

### Module import fails
- Check module status in Automation Account → Modules
- Ensure Microsoft.Graph.Authentication is imported first
- Wait for modules to finish importing before running runbooks

### "Connect-MgGraph: The term is not recognized"
- Module import may still be in progress
- Check Automation Account → Modules → verify status is "Available"

## 📖 Documentation

- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/)
- [Graph API Permissions Reference](https://learn.microsoft.com/graph/permissions-reference)
- [Azure Automation Managed Identities](https://learn.microsoft.com/azure/automation/automation-security-overview#managed-identities)

## 🎓 Next Steps

1. **Add more Graph modules** - Install other Microsoft.Graph.* modules
2. **Create reports** - Export data to Azure Storage or send via email
3. **Schedule runbooks** - Set up recurring schedules for reports
4. **Add filtering** - Enhance runbooks with more filtering options
5. **Integrate alerts** - Send notifications based on query results

## 📄 License

MIT License - See LICENSE file in repository root.

## ⚠️ Disclaimer

This is a **demo configuration** for learning purposes. Review security and compliance requirements before using in production.

---

**Scenario Version**: 1.0  
**Last Updated**: November 2025  
**Terraform Version**: >= 1.0  
**Provider Versions**: azurerm ~> 3.0, azuread ~> 2.0

---

Made with ❤️ for Azure Automation learners
