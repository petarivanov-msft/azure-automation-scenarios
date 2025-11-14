# ============================================================================
# Azure Automation - Start/Stop VMs with Tags
# ============================================================================
# This configuration deploys:
# - Azure Automation Account with managed identity
# - 3 Test VMs with different power management tags
# - Runbooks to start/stop VMs based on tags
# - Schedule for automated VM management
# - Cost optimization through automated shutdown
#
# Cloud Shell Compatible: Uses Bash and jq (no PowerShell dependencies)
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "azurerm_client_config" "current" {}

# ============================================================================
# Random Password for VMs
# ============================================================================

resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.resource_prefix}-startstop"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# Azure Automation Account
# ============================================================================

resource "azurerm_automation_account" "main" {
  name                = "${var.resource_prefix}-automation-startstop"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Basic"
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# ============================================================================
# PowerShell Modules
# ============================================================================

resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/2.13.2"
  }
}

resource "azurerm_automation_module" "az_compute" {
  name                    = "Az.Compute"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Compute/7.1.0"
  }

  depends_on = [azurerm_automation_module.az_accounts]
}

resource "azurerm_automation_module" "az_resources" {
  name                    = "Az.Resources"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Resources/6.12.0"
  }

  depends_on = [azurerm_automation_module.az_accounts]
}

# ============================================================================
# RBAC - Grant Automation Account Permissions
# ============================================================================

resource "azurerm_role_assignment" "automation_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# ============================================================================
# Networking
# ============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-vms"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.resource_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ============================================================================
# Test VMs with Different Power Management Tags
# ============================================================================

# VM 1 - AlwaysOn (Production)
resource "azurerm_network_interface" "vm1" {
  name                = "${var.resource_prefix}-nic-vm1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "${var.resource_prefix}-vm-prod"
  computer_name       = "vm-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result
  
  network_interface_ids = [azurerm_network_interface.vm1.id]

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
    Environment   = "Production"
    PowerSchedule = "AlwaysOn"
    CostCenter    = "IT-Operations"
  })
}

# VM 2 - BusinessHours (Development)
resource "azurerm_network_interface" "vm2" {
  name                = "${var.resource_prefix}-nic-vm2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "${var.resource_prefix}-vm-dev"
  computer_name       = "vm-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result
  
  network_interface_ids = [azurerm_network_interface.vm2.id]

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
    Environment   = "Development"
    PowerSchedule = "BusinessHours"
    CostCenter    = "Development"
  })
}

# VM 3 - NightShutdown (Testing)
resource "azurerm_network_interface" "vm3" {
  name                = "${var.resource_prefix}-nic-vm3"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm3" {
  name                = "${var.resource_prefix}-vm-test"
  computer_name       = "vm-test"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result
  
  network_interface_ids = [azurerm_network_interface.vm3.id]

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
    Environment   = "Testing"
    PowerSchedule = "NightShutdown"
    CostCenter    = "QA"
  })
}

# ============================================================================
# Automation Variables
# ============================================================================

resource "azurerm_automation_variable_string" "resource_group" {
  name                    = "ResourceGroupName"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  value                   = azurerm_resource_group.main.name
}

resource "azurerm_automation_variable_string" "timezone" {
  name                    = "TimeZone"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  value                   = var.timezone
}

# ============================================================================
# Runbook 1: Start VMs by Tag
# ============================================================================

resource "azurerm_automation_runbook" "start_vms" {
  name                    = "Start-VMsByTag"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Starts VMs based on PowerSchedule tag
    .DESCRIPTION
        Connects with managed identity and starts VMs matching the schedule tag
    .PARAMETER Schedule
        PowerSchedule tag value to filter VMs (e.g., BusinessHours, NightShutdown)
    #>
    
    param(
        [Parameter(Mandatory=$false)]
        [string]$Schedule = "BusinessHours"
    )
    
    Write-Output "=== Start VMs by Tag Runbook ==="
    Write-Output "Schedule filter: $Schedule"
    Write-Output "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    try {
        # Connect using managed identity
        Write-Output "`nConnecting to Azure using Managed Identity..."
        Connect-AzAccount -Identity | Out-Null
        
        $context = Get-AzContext
        Write-Output "Connected to subscription: $($context.Subscription.Name)"
        
        # Get resource group from automation variable
        $resourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
        Write-Output "Target resource group: $resourceGroupName"
        
        # Get VMs with matching PowerSchedule tag
        Write-Output "`nSearching for VMs with PowerSchedule=$Schedule..."
        $vms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object {
            $_.Tags.PowerSchedule -eq $Schedule
        }
        
        if ($vms.Count -eq 0) {
            Write-Output "No VMs found with PowerSchedule=$Schedule tag"
            return
        }
        
        Write-Output "Found $($vms.Count) VM(s) to start"
        Write-Output ""
        
        $startedCount = 0
        $alreadyRunningCount = 0
        $failedCount = 0
        
        foreach ($vm in $vms) {
            Write-Output "Processing VM: $($vm.Name)"
            Write-Output "  Environment: $($vm.Tags.Environment)"
            Write-Output "  PowerSchedule: $($vm.Tags.PowerSchedule)"
            
            # Get current power state
            $vmStatus = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Status
            $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
            
            Write-Output "  Current state: $powerState"
            
            if ($powerState -eq "running") {
                Write-Output "  Action: Already running, skipping"
                $alreadyRunningCount++
            }
            else {
                Write-Output "  Action: Starting VM..."
                try {
                    Start-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -NoWait | Out-Null
                    Write-Output "  Result: Start command sent successfully"
                    $startedCount++
                }
                catch {
                    Write-Error "  Result: Failed to start - $_"
                    $failedCount++
                }
            }
            Write-Output ""
        }
        
        # Summary
        Write-Output "=== Summary ==="
        Write-Output "Total VMs processed: $($vms.Count)"
        Write-Output "Started: $startedCount"
        Write-Output "Already running: $alreadyRunningCount"
        Write-Output "Failed: $failedCount"
        Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
    }
    catch {
        Write-Error "Runbook failed: $_"
        Write-Error $_.Exception.Message
        throw
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.az_accounts,
    azurerm_automation_module.az_compute
  ]
}

# ============================================================================
# Runbook 2: Stop VMs by Tag
# ============================================================================

resource "azurerm_automation_runbook" "stop_vms" {
  name                    = "Stop-VMsByTag"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Stops all VMs except AlwaysOn
    .DESCRIPTION
        Connects with managed identity and stops all VMs that don't have AlwaysOn tag
    #>
    
    Write-Output "=== Stop All VMs Runbook ==="
    Write-Output "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    try {
        # Connect using managed identity
        Write-Output "`nConnecting to Azure..."
        Connect-AzAccount -Identity | Out-Null
        Write-Output "Connected to: $((Get-AzContext).Subscription.Name)"
        
        # Get resource group
        $resourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
        Write-Output "Resource group: $resourceGroupName"
        
        # Get all VMs except AlwaysOn
        Write-Output "`nGetting VMs (excluding AlwaysOn)..."
        $vms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object {
            $_.Tags.PowerSchedule -ne "AlwaysOn"
        }
        
        if ($vms.Count -eq 0) {
            Write-Output "No VMs to stop (all are AlwaysOn or no VMs found)"
            return
        }
        
        Write-Output "Found $($vms.Count) VM(s) to stop`n"
        
        foreach ($vm in $vms) {
            Write-Output "VM: $($vm.Name) (PowerSchedule: $($vm.Tags.PowerSchedule))"
            
            # Get current state
            $vmStatus = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Status
            $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
            Write-Output "  Current: $powerState"
            
            if ($powerState -eq "deallocated" -or $powerState -eq "stopped") {
                Write-Output "  Action: Already stopped`n"
            }
            else {
                Write-Output "  Action: Stopping..."
                try {
                    Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Force | Out-Null
                    Write-Output "  Result: Stopped successfully`n"
                }
                catch {
                    Write-Error "  Error: $_`n"
                }
            }
        }
        
        Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    catch {
        Write-Error "Runbook failed: $_"
        throw
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.az_accounts,
    azurerm_automation_module.az_compute
  ]
}

# ============================================================================
# Runbook 3: Get VM Power State Report
# ============================================================================

resource "azurerm_automation_runbook" "vm_status" {
  name                    = "Get-VMPowerStateReport"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Reports power state of all VMs in resource group
    .DESCRIPTION
        Generates a report showing current power state and tags for all VMs
    #>
    
    Write-Output "=== VM Power State Report ==="
    Write-Output "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    try {
        # Connect using managed identity
        Connect-AzAccount -Identity | Out-Null
        
        $resourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
        
        Write-Output "`nResource Group: $resourceGroupName"
        Write-Output ""
        
        # Get all VMs
        $vms = Get-AzVM -ResourceGroupName $resourceGroupName
        
        if ($vms.Count -eq 0) {
            Write-Output "No VMs found in resource group"
            return
        }
        
        Write-Output "Total VMs: $($vms.Count)"
        Write-Output "=" * 100
        
        $runningCount = 0
        $stoppedCount = 0
        
        foreach ($vm in $vms) {
            $vmStatus = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Status
            $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
            
            if ($powerState -like "*running*") {
                $runningCount++
                $statusIcon = "🟢"
            }
            else {
                $stoppedCount++
                $statusIcon = "🔴"
            }
            
            Write-Output "`n$statusIcon VM: $($vm.Name)"
            Write-Output "   Power State: $powerState"
            Write-Output "   Environment: $($vm.Tags.Environment)"
            Write-Output "   PowerSchedule: $($vm.Tags.PowerSchedule)"
            Write-Output "   Cost Center: $($vm.Tags.CostCenter)"
            Write-Output "   Size: $($vm.HardwareProfile.VmSize)"
            Write-Output "   Location: $($vm.Location)"
        }
        
        Write-Output "`n" + ("=" * 100)
        Write-Output "Summary:"
        Write-Output "  Running: $runningCount"
        Write-Output "  Stopped: $stoppedCount"
        
    }
    catch {
        Write-Error "Runbook failed: $_"
        throw
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.az_accounts,
    azurerm_automation_module.az_compute
  ]
}

# ============================================================================
# Automation Schedules
# ============================================================================

# Morning schedule - Start VMs at 8:00 AM Monday-Friday
resource "azurerm_automation_schedule" "morning_start" {
  name                    = "Schedule-StartVMs-Morning"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  frequency               = "Week"
  interval                = 1
  timezone                = "UTC"
  start_time              = timeadd(timestamp(), "24h") # Start tomorrow
  description             = "Start VMs at 8:00 AM Monday-Friday"
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  
  # Schedule at 8:00 AM UTC (adjust timezone as needed)
  depends_on = [azurerm_automation_account.main]
}

# Evening schedule - Stop VMs at 6:00 PM Monday-Friday
resource "azurerm_automation_schedule" "evening_stop" {
  name                    = "Schedule-StopVMs-Evening"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  frequency               = "Week"
  interval                = 1
  timezone                = "UTC"
  start_time              = timeadd(timestamp(), "34h") # 10 hours after morning start
  description             = "Stop VMs at 6:00 PM Monday-Friday"
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  
  depends_on = [azurerm_automation_account.main]
}

# Night schedule - Stop VMs tagged as NightShutdown at 10:00 PM daily
resource "azurerm_automation_schedule" "night_shutdown" {
  name                    = "Schedule-StopVMs-Night"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = timeadd(timestamp(), "26h") # 2 hours after evening
  description             = "Stop VMs at 10:00 PM daily"
  
  depends_on = [azurerm_automation_account.main]
}

# ============================================================================
# Link Schedules to Runbooks
# ============================================================================

# Link morning schedule to Start-VMsByTag runbook
resource "azurerm_automation_job_schedule" "morning_start_link" {
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  schedule_name           = azurerm_automation_schedule.morning_start.name
  runbook_name            = azurerm_automation_runbook.start_vms.name

  parameters = {
    schedule = "BusinessHours"
  }

  depends_on = [
    azurerm_automation_schedule.morning_start,
    azurerm_automation_runbook.start_vms
  ]
}

# Link evening schedule to Stop-VMsByTag runbook
resource "azurerm_automation_job_schedule" "evening_stop_link" {
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  schedule_name           = azurerm_automation_schedule.evening_stop.name
  runbook_name            = azurerm_automation_runbook.stop_vms.name

  parameters = {
    schedule = "BusinessHours"
    force    = "false"
  }

  depends_on = [
    azurerm_automation_schedule.evening_stop,
    azurerm_automation_runbook.stop_vms
  ]
}

# Link night schedule to Stop-VMsByTag runbook (for NightShutdown tagged VMs)
resource "azurerm_automation_job_schedule" "night_shutdown_link" {
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  schedule_name           = azurerm_automation_schedule.night_shutdown.name
  runbook_name            = azurerm_automation_runbook.stop_vms.name

  parameters = {
    schedule = "NightShutdown"
    force    = "false"
  }

  depends_on = [
    azurerm_automation_schedule.night_shutdown,
    azurerm_automation_runbook.stop_vms
  ]
}

# ============================================================================
# Test Runbooks Manually
# ============================================================================
# Auto-testing removed for cross-platform compatibility
# Test runbooks manually via Azure Portal or Azure CLI:
#
# Get VM status report:
# az automation runbook start --automation-account-name "startstop-automation-startstop" --resource-group "rg-startstop-startstop" --name "Get-VMPowerStateReport"
#
# Start VMs by schedule:
# az automation runbook start --automation-account-name "startstop-automation-startstop" --resource-group "rg-startstop-startstop" --name "Start-VMsByTag" --parameters Schedule=BusinessHours
#
# Stop VMs by schedule:
# az automation runbook start --automation-account-name "startstop-automation-startstop" --resource-group "rg-startstop-startstop" --name "Stop-VMsByTag" --parameters Schedule=BusinessHours Force=false
