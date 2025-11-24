output "worker_group_name" {
  description = "Name of the Hybrid Worker Group"
  value       = azurerm_automation_hybrid_runbook_worker_group.main.name
}

output "vm_name" {
  description = "Name of the Hybrid Worker VM"
  value       = azurerm_windows_virtual_machine.hybrid_vm.name
}

output "vm_id" {
  description = "ID of the Hybrid Worker VM"
  value       = azurerm_windows_virtual_machine.hybrid_vm.id
}

output "vm_public_ip" {
  description = "Public IP address of the Hybrid Worker VM"
  value       = azurerm_public_ip.hybrid_vm.ip_address
}

output "vm_portal_url" {
  description = "Azure Portal URL for the Hybrid Worker VM"
  value       = "https://portal.azure.com/#@/resource${azurerm_windows_virtual_machine.hybrid_vm.id}"
}

output "runbook_name" {
  description = "Name of the test runbook"
  value       = azurerm_automation_runbook.test_hybrid_worker.name
}
