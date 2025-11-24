output "vm_names" {
  description = "Names of created VMs"
  value       = [for k, v in azurerm_windows_virtual_machine.vm : v.name]
}

output "vm_ids" {
  description = "IDs of created VMs"
  value       = [for k, v in azurerm_windows_virtual_machine.vm : v.id]
}

output "vm_power_schedules" {
  description = "Power schedule tags for each VM"
  value       = { for k, v in local.vms : v.name => v.power_schedule }
}

output "runbook_names" {
  description = "Names of Start/Stop runbooks"
  value = [
    azurerm_automation_runbook.start_vms_by_tag.name,
    azurerm_automation_runbook.stop_vms_by_tag.name,
    azurerm_automation_runbook.get_vm_power_state.name
  ]
}
