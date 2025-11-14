# ============================================================================
# Outputs for Azure Automation Microsoft Graph API Demo
# ============================================================================

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Automation Account
output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = azurerm_automation_account.main.name
}

output "automation_account_id" {
  description = "ID of the Automation Account"
  value       = azurerm_automation_account.main.id
}

output "automation_account_identity" {
  description = "Managed identity principal ID of the Automation Account"
  value       = azurerm_automation_account.main.identity[0].principal_id
}

# Tenant Information
output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

# Runbooks
output "get_users_runbook_name" {
  description = "Name of the Get Users runbook"
  value       = azurerm_automation_runbook.get_users.name
}

output "get_groups_runbook_name" {
  description = "Name of the Get Groups runbook"
  value       = azurerm_automation_runbook.get_groups.name
}

output "get_applications_runbook_name" {
  description = "Name of the Get Applications runbook"
  value       = azurerm_automation_runbook.get_applications.name
}

# Microsoft Graph Permissions Granted
output "graph_permissions" {
  description = "Microsoft Graph API permissions granted to the managed identity"
  value = [
    "User.Read.All",
    "Group.Read.All",
    "Application.Read.All",
    "Directory.Read.All"
  ]
}

# ============================================================================
# Azure Portal Links
# ============================================================================

output "portal_automation_account_link" {
  description = "Direct link to Automation Account in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}"
}

output "portal_resource_group_link" {
  description = "Direct link to Resource Group in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
}

output "portal_runbook_get_users_link" {
  description = "Direct link to Get Users runbook in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_users.id}"
}

output "portal_runbook_get_groups_link" {
  description = "Direct link to Get Groups runbook in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_groups.id}"
}

output "portal_runbook_get_applications_link" {
  description = "Direct link to Get Applications runbook in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_applications.id}"
}

# ============================================================================
# Summary Output
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║       Azure Automation - Microsoft Graph API Automation                  ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    📦 Resource Group: ${azurerm_resource_group.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}
    
    🤖 Automation Account: ${azurerm_automation_account.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}
    🆔 Managed Identity: ${azurerm_automation_account.main.identity[0].principal_id}
    
    📊 Microsoft Graph Permissions Granted:
       ✅ User.Read.All - Read all users
       ✅ Group.Read.All - Read all groups  
       ✅ Application.Read.All - Read all applications
       ✅ Directory.Read.All - Read directory data
    
    📜 Runbooks Available:
       • Get-UsersReport
         Description: Query users from Microsoft Graph
         Portal: https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_users.id}
       
       • Get-GroupsReport
         Description: Query groups from Microsoft Graph
         Portal: https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_groups.id}
       
       • Get-ApplicationsReport
         Description: Query app registrations from Microsoft Graph
         Portal: https://portal.azure.com/#@/resource${azurerm_automation_runbook.get_applications.id}
    
    📦 Microsoft.Graph Modules Installed:
       • Microsoft.Graph.Authentication (2.11.1)
       • Microsoft.Graph.Users (2.11.1)
       • Microsoft.Graph.Groups (2.11.1)
       • Microsoft.Graph.Applications (2.11.1)
    
    ✅ Test Runbook: ${var.auto_test_runbook ? "Executed automatically (Get-UsersReport)" : "Disabled"}
    
    📝 Next Steps:
       1. Click the Automation Account portal link above
       2. Go to "Runbooks" blade
       3. Review runbook job history (if auto-test enabled)
       4. Manually execute runbooks with different parameters
    
    🧪 Test Commands:
       # Execute Get-UsersReport
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Get-UsersReport" \\
         --parameters '{"TopCount":10}'
       
       # Execute Get-GroupsReport
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Get-GroupsReport" \\
         --parameters '{"TopCount":10,"GroupType":"Security"}'
    
    💰 Estimated Cost: ~$0-5/month (Automation Account only, first 500 min free)
    
    🧹 Cleanup: terraform destroy -auto-approve
    
  EOT
}
