# ============================================================================
# Azure Hybrid Worker Lab - Terraform Configuration
# ============================================================================
# This scenario demonstrates:
# - Windows VM with Hybrid Worker Extension
# - Azure Automation Account with managed identities
# - Hybrid Worker Group setup and VM registration
# - PowerShell module deployment (Az.Accounts, Az.Compute)
# - Test runbook with managed identity authentication
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ============================================================================
# Networking Resources
# ============================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ============================================================================
# Windows Virtual Machine
# ============================================================================

resource "random_password" "vm_password" {
  length  = 16
  special = true
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ============================================================================
# Azure Automation Account
# ============================================================================

resource "azurerm_automation_account" "automation" {
  name                = "${var.prefix}-automation"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ============================================================================
# Hybrid Worker Configuration
# ============================================================================

data "external" "automation_hybrid_url" {
  program = ["pwsh", "-Command", <<-EOT
    try {
      $subscriptionId = "${data.azurerm_subscription.current.subscription_id}"
      $resourceGroup = "${azurerm_resource_group.rg.name}"
      $automationAccount = "${azurerm_automation_account.automation.name}"
      
      $url = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Automation/automationAccounts/$automationAccount?api-version=2023-11-01"
      
      $result = az rest --method get --url $url 2>$null | ConvertFrom-Json
      $hybridUrl = $result.properties.automationHybridServiceUrl
      
      if (-not $hybridUrl) { $hybridUrl = "placeholder" }
      
      @{url = $hybridUrl} | ConvertTo-Json
    }
    catch {
      @{url = "placeholder"} | ConvertTo-Json
    }
  EOT
  ]

  depends_on = [
    azurerm_automation_account.automation
  ]
}

resource "random_uuid" "worker_id" {}

resource "azurerm_automation_hybrid_runbook_worker_group" "worker_group" {
  name                    = "${var.prefix}-worker-group"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
}

resource "azurerm_automation_hybrid_runbook_worker" "worker" {
  automation_account_name = azurerm_automation_account.automation.name
  resource_group_name     = azurerm_resource_group.rg.name
  worker_group_name       = azurerm_automation_hybrid_runbook_worker_group.worker_group.name
  vm_resource_id          = azurerm_windows_virtual_machine.vm.id
  worker_id               = random_uuid.worker_id.result
}

resource "azurerm_virtual_machine_extension" "hybrid_worker" {
  name                       = "HybridWorkerExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Automation.HybridWorker"
  type                       = "HybridWorkerForWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    AutomationAccountURL = data.external.automation_hybrid_url.result.url
  })

  protected_settings = jsonencode({
    HybridWorkerGroupName = azurerm_automation_hybrid_runbook_worker_group.worker_group.name
  })

  depends_on = [
    azurerm_automation_hybrid_runbook_worker.worker,
    data.external.automation_hybrid_url
  ]

  tags = var.tags
}

# ============================================================================
# Role Assignments
# ============================================================================

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "automation_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.automation.identity[0].principal_id

  depends_on = [
    azurerm_automation_account.automation
  ]
}

resource "azurerm_role_assignment" "vm_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
}

# ============================================================================
# PowerShell Modules Installation
# ============================================================================

resource "azurerm_virtual_machine_extension" "powershell_modules" {
  name                       = "InstallPowerShellModules"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name Az.Accounts -Force -AllowClobber; Install-Module -Name Az.Compute -Force -AllowClobber; Write-Host 'PowerShell modules installed successfully'\""
  })

  depends_on = [
    azurerm_virtual_machine_extension.hybrid_worker
  ]

  tags = var.tags
}

resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts"
  }
}

resource "azurerm_automation_module" "az_compute" {
  name                    = "Az.Compute"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Compute"
  }

  depends_on = [
    azurerm_automation_module.az_accounts
  ]
}

# ============================================================================
# Test Runbook
# ============================================================================

resource "azurerm_automation_runbook" "test_hybrid_worker" {
  name                    = "Test-HybridWorker-ManagedIdentity"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = true
  log_progress            = true
  description             = "Test runbook that uses managed identity to connect to Azure and list VMs"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Test runbook for Hybrid Worker using Managed Identity
    
    .DESCRIPTION
        This runbook demonstrates how to:
        1. Connect to Azure using the system-assigned managed identity
        2. List all VMs in the subscription
        3. Get details about the current VM
    #>
    
    Write-Output "=== Hybrid Worker Test Runbook ==="
    Write-Output "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output ""
    
    # Connect to Azure using the system-assigned managed identity
    Write-Output "Connecting to Azure using Managed Identity..."
    try {
        Connect-AzAccount -Identity -ErrorAction Stop
        Write-Output "Successfully connected to Azure!"
        
        $context = Get-AzContext
        Write-Output "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
        Write-Output "Tenant: $($context.Tenant.Id)"
        Write-Output ""
        
    } catch {
        Write-Error "Failed to connect to Azure: $_"
        throw
    }
    
    # List all VMs in the subscription
    Write-Output "--- Listing all VMs in the subscription ---"
    try {
        $vms = Get-AzVM
        Write-Output "Found $($vms.Count) VM(s) in the subscription:"
        Write-Output ""
        
        foreach ($vm in $vms) {
            Write-Output "VM Name: $($vm.Name)"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  Location: $($vm.Location)"
            Write-Output "  VM Size: $($vm.HardwareProfile.VmSize)"
            Write-Output "  OS Type: $($vm.StorageProfile.OsDisk.OsType)"
            Write-Output "  Provisioning State: $($vm.ProvisioningState)"
            Write-Output ""
        }
    } catch {
        Write-Error "Failed to list VMs: $_"
    }
    
    # Get details about the current VM
    Write-Output "--- Getting details about the Hybrid Worker VM ---"
    try {
        $currentVM = Get-AzVM -ResourceGroupName "${var.resource_group_name}" -Name "${var.prefix}-vm" -Status
        Write-Output "VM Name: $($currentVM.Name)"
        Write-Output "Power State: $($currentVM.PowerState)"
        Write-Output "VM Agent Status: $($currentVM.VMAgent.Statuses[0].DisplayStatus)"
        
        Write-Output ""
        Write-Output "Installed Extensions:"
        foreach ($ext in $currentVM.Extensions) {
            Write-Output "  - $($ext.Name) (Type: $($ext.Type))"
        }
        
    } catch {
        Write-Error "Failed to get current VM details: $_"
    }
    
    Write-Output ""
    Write-Output "--- Runbook execution completed successfully ---"
    Write-Output "End time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  EOT

  depends_on = [
    azurerm_automation_module.az_compute,
    azurerm_automation_hybrid_runbook_worker.worker
  ]

  tags = var.tags
}

# ============================================================================
# Publish and Test Runbook
# ============================================================================

resource "null_resource" "publish_runbook" {
  provisioner "local-exec" {
    command = <<-EOT
      $runbook = az automation runbook show `
        --automation-account-name ${azurerm_automation_account.automation.name} `
        --resource-group ${azurerm_resource_group.rg.name} `
        --name ${azurerm_automation_runbook.test_hybrid_worker.name} 2>$null | ConvertFrom-Json
      
      if ($runbook.state -ne "Published") {
        Write-Host "Publishing runbook..."
        az automation runbook publish `
          --automation-account-name ${azurerm_automation_account.automation.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --name ${azurerm_automation_runbook.test_hybrid_worker.name}
      } else {
        Write-Host "Runbook is already published"
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_automation_runbook.test_hybrid_worker
  ]

  triggers = {
    runbook_content = sha256(azurerm_automation_runbook.test_hybrid_worker.content)
  }
}

resource "null_resource" "run_test_runbook" {
  count = var.run_test_runbook ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Starting test runbook on hybrid worker..."
      
      $job = az automation runbook start `
        --automation-account-name ${azurerm_automation_account.automation.name} `
        --resource-group ${azurerm_resource_group.rg.name} `
        --name ${azurerm_automation_runbook.test_hybrid_worker.name} `
        --run-on ${azurerm_automation_hybrid_runbook_worker_group.worker_group.name} | ConvertFrom-Json
      
      $jobName = $job.name
      Write-Host "Job started: $jobName"
      
      # Wait for job completion (max 2 minutes)
      $maxWait = 120
      $waited = 0
      $status = "Running"
      
      while ($status -notin @("Completed", "Failed", "Stopped", "Suspended") -and $waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        
        $jobStatus = az automation job show `
          --automation-account-name ${azurerm_automation_account.automation.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --name $jobName | ConvertFrom-Json
        
        $status = $jobStatus.status
        Write-Host -NoNewline "."
      }
      
      Write-Host ""
      Write-Host "Job Status: $status"
      
      if ($status -eq "Completed") {
        Write-Host ""
        Write-Host "========== RUNBOOK OUTPUT =========="
        
        $subscriptionId = (az account show --query id -o tsv)
        $outputUrl = "/subscriptions/$subscriptionId/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Automation/automationAccounts/${azurerm_automation_account.automation.name}/jobs/$jobName/output?api-version=2023-11-01"
        
        $output = az rest --method get --url $outputUrl
        Write-Host $output
        
        Write-Host ""
        Write-Host "========== END OUTPUT =========="
      } else {
        Write-Host "Job did not complete successfully. Status: $status"
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    null_resource.publish_runbook,
    azurerm_virtual_machine_extension.hybrid_worker,
    azurerm_virtual_machine_extension.powershell_modules
  ]

  triggers = {
    always_run = timestamp()
  }
}
