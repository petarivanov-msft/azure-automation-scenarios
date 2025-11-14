# ============================================================================
# Outputs for Start/Stop VMs Demo
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
  description = "Managed identity principal ID of the Automation Account"
  value       = azurerm_automation_account.main.identity[0].principal_id
}

# VM Information
output "vm1_name" {
  description = "Production VM name (AlwaysOn)"
  value       = azurerm_windows_virtual_machine.vm1.name
}

output "vm2_name" {
  description = "Development VM name (BusinessHours)"
  value       = azurerm_windows_virtual_machine.vm2.name
}

output "vm3_name" {
  description = "Test VM name (NightShutdown)"
  value       = azurerm_windows_virtual_machine.vm3.name
}

output "admin_username" {
  description = "Admin username for VMs"
  value       = var.admin_username
}

output "admin_password" {
  description = "Admin password for VMs (sensitive)"
  value       = random_password.vm_password.result
  sensitive   = true
}

# Runbook Names
output "start_vms_runbook_name" {
  description = "Name of the Start VMs runbook"
  value       = azurerm_automation_runbook.start_vms.name
}

output "stop_vms_runbook_name" {
  description = "Name of the Stop VMs runbook"
  value       = azurerm_automation_runbook.stop_vms.name
}

output "vm_status_runbook_name" {
  description = "Name of the VM Status Report runbook"
  value       = azurerm_automation_runbook.vm_status.name
}

# Schedule Information
output "morning_schedule_name" {
  description = "Name of the morning start schedule (8 AM Mon-Fri)"
  value       = azurerm_automation_schedule.morning_start.name
}

output "evening_schedule_name" {
  description = "Name of the evening stop schedule (6 PM Mon-Fri)"
  value       = azurerm_automation_schedule.evening_stop.name
}

output "night_schedule_name" {
  description = "Name of the night shutdown schedule (10 PM daily)"
  value       = azurerm_automation_schedule.night_shutdown.name
}

# Portal Links
output "portal_automation_account_link" {
  description = "Direct link to Automation Account in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}"
}

output "portal_resource_group_link" {
  description = "Direct link to Resource Group in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
}

output "portal_vm1_link" {
  description = "Direct link to Production VM"
  value       = "https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm1.id}"
}

output "portal_vm2_link" {
  description = "Direct link to Development VM"
  value       = "https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm2.id}"
}

output "portal_vm3_link" {
  description = "Direct link to Test VM"
  value       = "https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm3.id}"
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║           Azure Automation - Start/Stop VMs with Tags                    ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    📦 Resource Group: ${azurerm_resource_group.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}
    
    🤖 Automation Account: ${azurerm_automation_account.main.name}
    🔗 Portal: https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}
    
    🖥️  Virtual Machines:
       
       1️⃣  ${azurerm_windows_virtual_machine.vm1.name}
          PowerSchedule: AlwaysOn (never auto-stopped)
          Environment: Production
          Portal: https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm1.id}
       
       2️⃣  ${azurerm_windows_virtual_machine.vm2.name}
          PowerSchedule: BusinessHours (8 AM - 6 PM)
          Environment: Development
          Portal: https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm2.id}
       
       3️⃣  ${azurerm_windows_virtual_machine.vm3.name}
          PowerSchedule: NightShutdown (stopped at night)
          Environment: Testing
          Portal: https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.vm3.id}
    
    📜 Runbooks:
       • Start-VMsByTag - Start VMs matching PowerSchedule tag
       • Stop-VMsByTag - Stop VMs matching PowerSchedule tag
       • Get-VMPowerStateReport - Report VM power states
    
    ⏰ Automated Schedules:
       • Morning Start (Mon-Fri 8:00 AM UTC)
         └─ Runs: Start-VMsByTag with Schedule=BusinessHours
       
       • Evening Stop (Mon-Fri 6:00 PM UTC)
         └─ Runs: Stop-VMsByTag with Schedule=BusinessHours
       
       • Night Shutdown (Daily 10:00 PM UTC)
         └─ Runs: Stop-VMsByTag with Schedule=NightShutdown
    
    🔑 VM Credentials:
       Username: ${var.admin_username}
       Password: (run 'terraform output admin_password' to view)
    
    💡 Test Commands:
       
       # Get VM status report
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Get-VMPowerStateReport"
       
       # Start BusinessHours VMs
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Start-VMsByTag" \\
         --parameters '{"Schedule":"BusinessHours"}'
       
       # Stop BusinessHours VMs
       az automation runbook start \\
         --automation-account-name "${azurerm_automation_account.main.name}" \\
         --resource-group "${azurerm_resource_group.main.name}" \\
         --name "Stop-VMsByTag" \\
         --parameters '{"Schedule":"BusinessHours"}'
    
    💰 Estimated Cost:
       - 3 VMs (if running 24/7): ~$90/month
       - With BusinessHours schedule: ~$45/month (50% savings!)
       - With NightShutdown: ~$60/month (33% savings!)
       - Automation Account: First 500 minutes free
    
    🧹 Cleanup: terraform destroy -auto-approve
    
  EOT
}
