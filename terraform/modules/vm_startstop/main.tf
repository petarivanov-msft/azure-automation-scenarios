# ============================================================================
# Start/Stop VMs Module
# ============================================================================
# Creates VMs with different power schedule tags and runbooks to manage them
# ============================================================================

# RBAC - Grant Automation Account Permissions
resource "azurerm_role_assignment" "automation_vm_contributor" {
  scope                = var.resource_group_name
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.managed_identity_principal_id
  skip_service_principal_aad_check = true
}

# ============================================================================
# Test VMs with Different Power Management Tags
# ============================================================================

locals {
  vms = {
    prod = {
      name            = "vm-prod"
      power_schedule  = "AlwaysOn"
      environment     = "Production"
    }
    dev = {
      name            = "vm-dev"
      power_schedule  = "BusinessHours"
      environment     = "Development"
    }
    test = {
      name            = "vm-test"
      power_schedule  = "NightShutdown"
      environment     = "Test"
    }
  }
}

# Network Interfaces
resource "azurerm_network_interface" "vm" {
  for_each            = local.vms
  name                = "nic-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = local.vms
  name                = each.value.name
  computer_name       = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  
  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = merge(var.tags, {
    Environment   = each.value.environment
    PowerSchedule = each.value.power_schedule
  })
}

# ============================================================================
# Runbooks for Start/Stop VMs
# ============================================================================

resource "azurerm_automation_runbook" "start_vms_by_tag" {
  name                    = "Start-VMsByTag"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Start-VMsByTag.ps1")
  tags    = var.tags
}

resource "azurerm_automation_runbook" "stop_vms_by_tag" {
  name                    = "Stop-VMsByTag"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Stop-VMsByTag.ps1")
  tags    = var.tags
}

resource "azurerm_automation_runbook" "get_vm_power_state" {
  name                    = "Get-VMPowerStateReport"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Get-VMPowerStateReport.ps1")
  tags    = var.tags
}
