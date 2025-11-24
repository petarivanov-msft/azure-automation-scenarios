output "runtime_environment_name" {
  description = "Name of the PowerShell 7.4 runtime environment"
  value       = "ps74-runtime"
}

output "runbook_names" {
  description = "Names of PowerShell 7.4 demo runbooks"
  value = [
    azurerm_automation_runbook.ps74_features.name,
    azurerm_automation_runbook.parallel_processing.name,
    azurerm_automation_runbook.resource_inventory.name
  ]
}

output "powershell_version" {
  description = "PowerShell version"
  value       = "7.4"
}
