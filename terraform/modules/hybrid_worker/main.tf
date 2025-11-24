# ============================================================================
# Hybrid Worker Module
# ============================================================================
# Creates Windows VM with Hybrid Worker extension and test runbook
# ============================================================================

# Public IP for Hybrid Worker VM
resource "azurerm_public_ip" "hybrid_vm" {
  name                = "pip-hybrid-worker"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface
resource "azurerm_network_interface" "hybrid_vm" {
  name                = "nic-hybrid-worker"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hybrid_vm.id
  }

  tags = var.tags
}

# Windows VM for Hybrid Worker
resource "azurerm_windows_virtual_machine" "hybrid_vm" {
  name                = "vm-hybrid-worker"
  computer_name       = "hwvm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  
  network_interface_ids = [azurerm_network_interface.hybrid_vm.id]

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

  tags = var.tags
}

# Hybrid Worker Group
resource "azurerm_automation_hybrid_runbook_worker_group" "main" {
  name                    = "hybrid-worker-group"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
}

# Hybrid Worker Extension
resource "azurerm_virtual_machine_extension" "hybrid_worker" {
  name                       = "HybridWorkerExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.hybrid_vm.id
  publisher                  = "Microsoft.Azure.Automation.HybridWorker"
  type                       = "HybridWorkerForWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    AutomationAccountURL = "https://${var.location}.agentsvc.azure-automation.net/accounts/${split("/", var.automation_account_id)[8]}"
  })

  depends_on = [azurerm_automation_hybrid_runbook_worker_group.main]
}

# Register VM with Hybrid Worker Group
resource "azurerm_automation_hybrid_runbook_worker" "main" {
  automation_account_name = var.automation_account_name
  resource_group_name     = var.resource_group_name
  worker_group_name       = azurerm_automation_hybrid_runbook_worker_group.main.name
  vm_resource_id          = azurerm_windows_virtual_machine.hybrid_vm.id
  worker_id               = azurerm_windows_virtual_machine.hybrid_vm.id

  depends_on = [azurerm_virtual_machine_extension.hybrid_worker]
}

# RBAC for VM managed identity
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine.hybrid_vm.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# RBAC for Automation Account managed identity
resource "azurerm_role_assignment" "automation_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = var.automation_identity_principal_id
  skip_service_principal_aad_check = true
}

# Test Runbook
resource "azurerm_automation_runbook" "test_hybrid_worker" {
  name                    = "Test-HybridWorker-ManagedIdentity"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Test-HybridWorker-ManagedIdentity.ps1")
  tags    = var.tags

  depends_on = [azurerm_automation_hybrid_runbook_worker.main]
}
