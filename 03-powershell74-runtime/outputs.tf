# ============================================================================
# Outputs for PowerShell 7.4 Runtime Demo
# ============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = azurerm_automation_account.main.name
}

output "automation_account_identity" {
  description = "Managed identity principal ID"
  value       = azurerm_automation_account.main.identity[0].principal_id
}

output "runtime_environment_name" {
  description = "Name of the PowerShell 7.4 runtime environment"
  value       = "ps74-runtime"
}

output "runtime_packages" {
  description = "Packages installed in PowerShell 7.4 runtime"
  value = [
    "Az.Accounts (3.0.4)",
    "Az.Compute (8.3.0)",
    "Az.Storage (7.3.0)",
    "Az.Resources (7.4.0)",
    "Az.Monitor (5.2.1)"
  ]
}

output "runbook_ps74_features_name" {
  description = "Name of PowerShell 7.4 features demo runbook"
  value       = azurerm_automation_runbook.ps74_features.name
}

output "runbook_parallel_processing_name" {
  description = "Name of parallel processing demo runbook"
  value       = azurerm_automation_runbook.parallel_processing.name
}

output "runbook_modern_query_name" {
  description = "Name of modern query runbook"
  value       = azurerm_automation_runbook.modern_query.name
}

# Portal Links
output "portal_automation_account_link" {
  description = "Direct link to Automation Account"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}"
}

output "portal_resource_group_link" {
  description = "Direct link to Resource Group"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
}

# Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║         Azure Automation - PowerShell 7.4 Runtime Environment            ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    📦 Resource Group: ${azurerm_resource_group.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}
    
    🤖 Automation Account: ${azurerm_automation_account.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}
    
    🚀 PowerShell 7.4 Runtime Environment: ps74-runtime
       Features:
       ✅ Ternary operators (? :)
       ✅ Null coalescing (??)
       ✅ Pipeline chain operators (&& ||)
       ✅ ForEach-Object -Parallel
       ✅ Modern error handling
       ✅ Improved performance
    
    📦 Installed Modules (Latest Versions):
       • Az.Accounts (3.0.4)
       • Az.Compute (8.3.0)
       • Az.Storage (7.3.0)
       • Az.Resources (7.4.0)
       • Az.Monitor (5.2.1)
    
    📜 Demo Runbooks:
       
       1️⃣  Demo-PowerShell74-Features
          Showcases new PS 7.4 syntax and features
          
       2️⃣  Demo-ParallelProcessing
          Compares sequential vs parallel processing
          Shows performance improvements
          
       3️⃣  Get-AzureResourceInventory
          Modern resource querying with PS 7.4
          Generates comprehensive inventory reports
    
    💡 Test Commands:
       
       # Run PS 7.4 features demo
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Demo-PowerShell74-Features"
       
       # Run parallel processing demo
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Demo-ParallelProcessing"
       
       # Get resource inventory
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Get-AzureResourceInventory" \\
         --parameters '{"TopResourceGroups":10}'
    
    💰 Estimated Cost: ~$0-5/month (First 500 minutes free!)
    
    🧹 Cleanup: terraform destroy -auto-approve
    
  EOT
}
