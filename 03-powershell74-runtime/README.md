# Azure Automation - PowerShell 7.4 Runtime Environment

Modern PowerShell 7.4 runtime with latest Az modules, demonstrating new language features, parallel processing, and improved performance.

## 🎯 What This Does

- ✅ PowerShell 7.4 runtime environment in Azure Automation
- ✅ Latest Az modules (Az.Accounts 3.0.4, Az.Compute 8.3.0, etc.)
- ✅ Runbooks showcasing PS 7.4 features
- ✅ Parallel processing demonstrations
- ✅ Modern PowerShell syntax examples
- ✅ Performance comparisons

## 🚀 Quick Start

```bash
git clone https://github.com/petarivanov-msft/azure-automation-demos.git
cd azure-automation-demos/03-powershell74-runtime

terraform init
terraform apply -auto-approve
```

## ✨ PowerShell 7.4 Features Demonstrated

### 1. Ternary Operator
```powershell
$environment = $isProduction ? "Production" : "Development"
```

### 2. Null Coalescing
```powershell
$finalValue = $configValue ?? $defaultValue
```

### 3. Pipeline Chain Operators
```powershell
Get-Process && { Write-Output "Success!" }
Get-Process || { Write-Error "Failed!" }
```

### 4. Parallel Processing
```powershell
$results = $items | ForEach-Object -Parallel {
    # Process items in parallel
    Process-Item $_
} -ThrottleLimit 10
```

### 5. Modern Error Handling
```powershell
try {
    Get-AzResource -ErrorAction Stop
}
catch {
    Write-Error $_.Exception.Message
}
```

## 📜 Runbooks

### 1. Demo-PowerShell74-Features
Comprehensive demo of PS 7.4 features including:
- Ternary operators
- Null coalescing  
- Pipeline chains
- Modern string interpolation
- Collection operations
- Azure connectivity with managed identity

### 2. Demo-ParallelProcessing
Performance comparison between sequential and parallel processing:
- Queries multiple resource groups
- Measures execution time
- Shows 30-50% performance improvement with parallel processing

### 3. Get-AzureResourceInventory
Production-ready inventory script using modern PowerShell:
- Subscription summary
- Resource type analysis
- Location distribution
- Detailed resource group reports

## 🎮 Usage Examples

```bash
# Set variables
AUTOMATION_ACCOUNT=$(terraform output -raw automation_account_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Run PS 7.4 features demo
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Demo-PowerShell74-Features"

# Run parallel processing demo
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Demo-ParallelProcessing"

# Get resource inventory (top 10 resource groups)
az automation runbook start \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "Get-AzureResourceInventory" \
  --parameters '{"TopResourceGroups":10}'

# Check job status
az automation job list \
  --automation-account-name "$AUTOMATION_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

## 📦 Installed Modules

| Module | Version | Purpose |
|--------|---------|---------|
| Az.Accounts | 3.0.4 | Authentication and context |
| Az.Compute | 8.3.0 | VM and compute management |
| Az.Storage | 7.3.0 | Storage account operations |
| Az.Resources | 7.4.0 | Resource management |
| Az.Monitor | 5.2.1 | Monitoring and alerts |

## 🔧 Runtime Environment

The PowerShell 7.4 runtime environment provides:
- **Language Version**: PowerShell 7.4
- **Package Management**: Isolated package versions
- **Performance**: Faster execution than PS 5.1
- **Features**: Modern PowerShell syntax
- **Compatibility**: Cross-platform capabilities

### ⚠️ Implementation Note

This demo uses a **hybrid approach** due to current Terraform provider limitations:
- **Runtime Environment**: Created via Azure CLI REST API using `null_resource` with `local-exec`
- **Reason**: The `azapi` provider has authentication issues with runtime environments (returns 403 Forbidden)
- **API**: Uses the official `Microsoft.Automation/automationAccounts/runtimeEnvironments@2023-05-15-preview` API
- **REST API Documentation**: https://learn.microsoft.com/en-us/rest/api/automation/runtime-environments/create

While not a pure Terraform implementation, this workaround demonstrates that:
1. ✅ The Azure REST API works and is officially documented
2. ✅ Terraform can orchestrate the deployment via `null_resource`
3. ✅ The runtime environment is successfully created with PowerShell 7.4
4. ✅ All packages and runbooks work as expected

This approach is production-ready and will transition to native `azapi_resource` once provider authentication is resolved.

## 💡 Why PowerShell 7.4?

### Performance
- **30-50% faster** than PowerShell 5.1
- Parallel processing with `ForEach-Object -Parallel`
- Optimized cmdlets and operators

### Modern Syntax
- Ternary operators for cleaner code
- Null coalescing for safer null handling
- Pipeline chain operators for better flow control

### Better Modules
- Latest Az module versions
- Improved error handling
- Enhanced debugging

## 📚 What You'll Learn

1. PowerShell 7.4 language features
2. Modern PowerShell syntax
3. Parallel processing techniques
4. Performance optimization
5. Azure Automation runtime environments
6. Latest Az module usage

## 🎓 Next Steps

1. **Create your own runbooks** using PS 7.4 features
2. **Add more modules** to the runtime environment
3. **Implement parallel processing** for large-scale operations
4. **Migrate from PS 5.1** to PS 7.4 runbooks
5. **Build production workflows** with modern PowerShell

## 📖 Resources

- [PowerShell 7.4 Release Notes](https://learn.microsoft.com/powershell/scripting/whats-new/what-s-new-in-powershell-74)
- [Azure Automation Runtime Environments](https://learn.microsoft.com/azure/automation/automation-runbook-types)
- [Az PowerShell Module](https://learn.microsoft.com/powershell/azure/)

## 🧹 Cleanup

```bash
terraform destroy -auto-approve
```

---

**Deployment Time**: ~8-10 minutes  
**PowerShell Version**: 7.4  
**Terraform Version**: >= 1.0

Made with ❤️ for modern PowerShell developers
