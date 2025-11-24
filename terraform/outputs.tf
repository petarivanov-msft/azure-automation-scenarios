# ============================================================================
# Outputs
# ============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_portal_url" {
  description = "Azure Portal URL for the resource group"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
}

output "location" {
  description = "Azure region"
  value       = var.location
}

# Automation Account Outputs
output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = module.automation_account.automation_account_name
}

output "automation_account_portal_url" {
  description = "Azure Portal URL for Automation Account"
  value       = "https://portal.azure.com/#@/resource${module.automation_account.automation_account_id}"
}

output "automation_identity_principal_id" {
  description = "Principal ID of Automation Account managed identity"
  value       = module.automation_account.managed_identity_principal_id
}

# Graph API Scenario Outputs
output "graph_api_runbooks" {
  description = "Graph API runbook names"
  value       = var.enable_graph_api ? module.graph_api[0].runbook_names : []
}

# Start/Stop VMs Scenario Outputs
output "startstop_vm_names" {
  description = "Names of Start/Stop VMs"
  value       = var.enable_startstop_vms ? module.vm_startstop[0].vm_names : []
}

output "startstop_vm_power_schedules" {
  description = "Power schedule tags for VMs"
  value       = var.enable_startstop_vms ? module.vm_startstop[0].vm_power_schedules : {}
}

output "startstop_runbooks" {
  description = "Start/Stop runbook names"
  value       = var.enable_startstop_vms ? module.vm_startstop[0].runbook_names : []
}

# PowerShell 7.4 Scenario Outputs
output "powershell74_runtime_name" {
  description = "Name of PowerShell 7.4 runtime environment"
  value       = var.enable_powershell74 ? module.powershell74_runtime[0].runtime_environment_name : null
}

output "powershell74_runbooks" {
  description = "PowerShell 7.4 runbook names"
  value       = var.enable_powershell74 ? module.powershell74_runtime[0].runbook_names : []
}

# Hybrid Worker Scenario Outputs
output "hybrid_worker_group_name" {
  description = "Name of Hybrid Worker Group"
  value       = var.enable_hybrid_worker ? module.hybrid_worker[0].worker_group_name : null
}

output "hybrid_worker_vm_name" {
  description = "Name of Hybrid Worker VM"
  value       = var.enable_hybrid_worker ? module.hybrid_worker[0].vm_name : null
}

output "hybrid_worker_vm_public_ip" {
  description = "Public IP of Hybrid Worker VM"
  value       = var.enable_hybrid_worker ? module.hybrid_worker[0].vm_public_ip : null
}

output "hybrid_worker_vm_portal_url" {
  description = "Azure Portal URL for Hybrid Worker VM"
  value       = var.enable_hybrid_worker ? module.hybrid_worker[0].vm_portal_url : null
}

# VM Credentials (password is sensitive)
output "vm_admin_username" {
  description = "Admin username for VMs"
  value       = var.vm_admin_username
}

output "vm_admin_password" {
  description = "Admin password for VMs (use: terraform output -raw vm_admin_password)"
  value       = local.vm_password
  sensitive   = true
}

# Summary
output "deployment_summary" {
  description = "Summary of deployed scenarios"
  value = {
    graph_api_enabled       = var.enable_graph_api
    startstop_vms_enabled   = var.enable_startstop_vms
    powershell74_enabled    = var.enable_powershell74
    hybrid_worker_enabled   = var.enable_hybrid_worker
    total_scenarios_enabled = (var.enable_graph_api ? 1 : 0) + (var.enable_startstop_vms ? 1 : 0) + (var.enable_powershell74 ? 1 : 0) + (var.enable_hybrid_worker ? 1 : 0)
  }
}
