# ============================================================================
# Azure Automation - PowerShell 7.4 Runtime Environment
# ============================================================================
# This configuration deploys:
# - Azure Automation Account with PowerShell 7.4 runtime
# - Runtime environment with modern Az modules
# - Sample runbooks demonstrating PS 7.4 features
# - Parallel processing capabilities
# - Modern PowerShell syntax and features
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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "azurerm_client_config" "current" {}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.resource_prefix}-ps74"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# Azure Automation Account
# ============================================================================

resource "azurerm_automation_account" "main" {
  name                = "${var.resource_prefix}-automation-ps74"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Basic"
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# ============================================================================
# PowerShell 7.4 Runtime Environment
# ============================================================================
# NOTE: The azapi provider has authentication issues with runtime environments.
# We use Azure CLI via local-exec as a workaround since it has proper permissions.

resource "null_resource" "ps74_runtime" {
  triggers = {
    automation_account_id = azurerm_automation_account.main.id
    runtime_version       = "7.4"
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method put `
        --url "https://management.azure.com${azurerm_automation_account.main.id}/runtimeEnvironments/ps74-runtime?api-version=2023-05-15-preview" `
        --body '{\"location\": \"${azurerm_resource_group.main.location}\", \"properties\": {\"runtime\": {\"language\": \"PowerShell\", \"version\": \"7.4\"}, \"description\": \"PowerShell 7.4 runtime environment with modern Az modules\", \"defaultPackages\": {}}}'
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      az rest --method delete `
        --url "https://management.azure.com${self.triggers.automation_account_id}/runtimeEnvironments/ps74-runtime?api-version=2023-05-15-preview"
    EOT
    interpreter = ["pwsh", "-Command"]
    on_failure  = continue
  }
}

# ============================================================================
# Add Packages to PowerShell 7.4 Runtime
# ============================================================================
# NOTE: Using Azure CLI via local-exec due to azapi auth issues

locals {
  runtime_id = "${azurerm_automation_account.main.id}/runtimeEnvironments/ps74-runtime"
  packages = {
    "Az.Accounts" = "3.0.4"
    "Az.Compute"  = "8.3.0"
    "Az.Storage"  = "7.3.0"
    "Az.Resources" = "7.4.0"
    "Az.Monitor"  = "5.2.1"
  }
}

resource "null_resource" "runtime_packages" {
  for_each = local.packages

  triggers = {
    runtime_id = null_resource.ps74_runtime.id
    package    = each.key
    version    = each.value
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method put `
        --url "https://management.azure.com${local.runtime_id}/packages/${each.key}?api-version=2023-05-15-preview" `
        --body '{\"properties\": {\"contentLink\": {\"uri\": \"https://www.powershellgallery.com/api/v2/package/${each.key}/${each.value}\"}}}'
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [null_resource.ps74_runtime]
}

# ============================================================================
# RBAC - Grant Automation Account Permissions
# ============================================================================

resource "azurerm_role_assignment" "automation_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# Grant subscription-level Reader for demo purposes
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "automation_subscription_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# ============================================================================
# Runbook 1: PowerShell 7.4 Features Demo
# ============================================================================

resource "azurerm_automation_runbook" "ps74_features" {
  name                    = "Demo-PowerShell74-Features"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"  # PowerShell type supports runtime environments

  content = <<-EOT
    #Requires -Version 7.4
    <#
    .SYNOPSIS
        Demonstrates PowerShell 7.4 features and modern syntax
    .DESCRIPTION
        Shows off new PowerShell 7.4 capabilities including:
        - Ternary operators
        - Null coalescing
        - Pipeline chains
        - ForEach-Object -Parallel
        - Modern error handling
    #>
    
    Write-Output "=== PowerShell 7.4 Features Demo ==="
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Output "Runtime: $($PSVersionTable.PSEdition)"
    Write-Output ""
    
    # Feature 1: Ternary Operator
    Write-Output "--- Feature 1: Ternary Operator ---"
    $isProduction = $true
    $environment = $isProduction ? "Production" : "Development"
    Write-Output "Environment: $environment"
    
    # Feature 2: Null Coalescing
    Write-Output "`n--- Feature 2: Null Coalescing ---"
    $configValue = $null
    $defaultValue = "default-config"
    $finalValue = $configValue ?? $defaultValue
    Write-Output "Final Value: $finalValue"
    
    # Feature 3: Pipeline Chain Operators
    Write-Output "`n--- Feature 3: Pipeline Chain Operators ---"
    $numbers = 1..5
    $result = $numbers | Where-Object { $_ -gt 3 } && {
        Write-Output "Found numbers greater than 3"
        $_
    }
    Write-Output "Result: $($result -join ', ')"
    
    # Feature 4: Connect to Azure
    Write-Output "`n--- Feature 4: Azure Connection with Managed Identity ---"
    try {
        Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
        $context = Get-AzContext
        Write-Output "✅ Connected to Azure"
        Write-Output "   Subscription: $($context.Subscription.Name)"
        Write-Output "   Account: $($context.Account.Id)"
        Write-Output "   Tenant: $($context.Tenant.Id)"
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
    }
    
    # Feature 5: Modern Error Handling with Simplified Try-Catch
    Write-Output "`n--- Feature 5: Resource Enumeration ---"
    try {
        $resourceGroups = Get-AzResourceGroup | Select-Object -First 5
        Write-Output "Found $($resourceGroups.Count) resource groups (showing first 5):"
        
        foreach ($rg in $resourceGroups) {
            Write-Output "  📦 $($rg.ResourceGroupName) [$($rg.Location)]"
        }
    }
    catch {
        Write-Error "Error getting resource groups: $($_.Exception.Message)"
    }
    
    # Feature 6: String Interpolation and Formatting
    Write-Output "`n--- Feature 6: Modern String Features ---"
    $vmCount = 42
    $region = "eastus"
    Write-Output "We have $vmCount VMs in $region"
    Write-Output "Status: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    # Feature 7: Array and Collection Features
    Write-Output "`n--- Feature 7: Collection Operations ---"
    $data = @(1, 2, 3, 4, 5)
    $doubled = $data.ForEach({ $_ * 2 })
    Write-Output "Original: $($data -join ', ')"
    Write-Output "Doubled: $($doubled -join ', ')"
    
    Write-Output "`n=== Demo Complete ==="
    Write-Output "PowerShell 7.4 is awesome! 🚀"
  EOT

  tags = var.tags
}

# Link runbook to PowerShell 7.4 runtime environment
resource "null_resource" "link_ps74_features_runtime" {
  triggers = {
    runbook_id     = azurerm_automation_runbook.ps74_features.id
    runtime_id     = null_resource.ps74_runtime.id
    packages       = join(",", keys(local.packages))
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method patch `
        --url "https://management.azure.com${azurerm_automation_runbook.ps74_features.id}?api-version=2024-10-23" `
        --body '{\"properties\": {\"type\": \"PowerShell\", \"runtimeEnvironment\": \"ps74-runtime\"}}'
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_automation_runbook.ps74_features,
    null_resource.runtime_packages
  ]
}

# ============================================================================
# Runbook 2: Parallel Processing Demo
# ============================================================================

resource "azurerm_automation_runbook" "parallel_processing" {
  name                    = "Demo-ParallelProcessing"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    #Requires -Version 7.4
    <#
    .SYNOPSIS
        Demonstrates parallel processing in PowerShell 7.4
    .DESCRIPTION
        Shows ForEach-Object -Parallel for faster resource queries
    #>
    
    Write-Output "=== Parallel Processing Demo ==="
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
    
    # Connect to Azure
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected to Azure"
    
    # Get all resource groups
    $resourceGroups = Get-AzResourceGroup | Select-Object -First 10
    Write-Output "`nFound $($resourceGroups.Count) resource groups (processing first 10)"
    
    # Sequential Processing (Traditional)
    Write-Output "`n--- Sequential Processing ---"
    $sequentialStart = Get-Date
    
    $sequentialResults = $resourceGroups | ForEach-Object {
        $rg = $_
        $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
        [PSCustomObject]@{
            ResourceGroup = $rg.ResourceGroupName
            ResourceCount = $resources.Count
            Location      = $rg.Location
        }
    }
    
    $sequentialDuration = (Get-Date) - $sequentialStart
    Write-Output "Sequential processing took: $($sequentialDuration.TotalSeconds) seconds"
    
    # Parallel Processing (PowerShell 7+)
    Write-Output "`n--- Parallel Processing ---"
    $parallelStart = Get-Date
    
    $parallelResults = $resourceGroups | ForEach-Object -Parallel {
        $rg = $_
        $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
        [PSCustomObject]@{
            ResourceGroup = $rg.ResourceGroupName
            ResourceCount = $resources.Count
            Location      = $rg.Location
        }
    } -ThrottleLimit 5  # Process 5 at a time
    
    $parallelDuration = (Get-Date) - $parallelStart
    Write-Output "Parallel processing took: $($parallelDuration.TotalSeconds) seconds"
    
    # Performance Comparison
    $improvement = [math]::Round((($sequentialDuration.TotalSeconds - $parallelDuration.TotalSeconds) / $sequentialDuration.TotalSeconds) * 100, 2)
    Write-Output "`n--- Performance Comparison ---"
    Write-Output "Sequential: $($sequentialDuration.TotalSeconds)s"
    Write-Output "Parallel: $($parallelDuration.TotalSeconds)s"
    Write-Output "Improvement: $improvement%"
    
    # Display Results
    Write-Output "`n--- Resource Group Summary ---"
    $parallelResults | ForEach-Object {
        Write-Output "$($_.ResourceGroup): $($_.ResourceCount) resources [$($_.Location)]"
    }
    
    Write-Output "`n=== Demo Complete ==="
  EOT

  tags = var.tags
}

# Link runbook to PowerShell 7.4 runtime environment
resource "null_resource" "link_parallel_processing_runtime" {
  triggers = {
    runbook_id     = azurerm_automation_runbook.parallel_processing.id
    runtime_id     = null_resource.ps74_runtime.id
    packages       = join(",", keys(local.packages))
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method patch `
        --url "https://management.azure.com${azurerm_automation_runbook.parallel_processing.id}?api-version=2024-10-23" `
        --body '{\"properties\": {\"type\": \"PowerShell\", \"runtimeEnvironment\": \"ps74-runtime\"}}'
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_automation_runbook.parallel_processing,
    null_resource.runtime_packages
  ]
}

# ============================================================================
# Runbook 3: Modern Azure Resource Query
# ============================================================================

resource "azurerm_automation_runbook" "modern_query" {
  name                    = "Get-AzureResourceInventory"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    #Requires -Version 7.4
    <#
    .SYNOPSIS
        Modern Azure resource inventory using PowerShell 7.4
    .DESCRIPTION
        Demonstrates modern PowerShell features for Azure resource management
    #>
    
    param(
        [int]$TopResourceGroups = 5
    )
    
    Write-Output "=== Azure Resource Inventory ==="
    Write-Output "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    # Connect
    Connect-AzAccount -Identity | Out-Null
    $context = Get-AzContext
    Write-Output "Subscription: $($context.Subscription.Name)"
    Write-Output ""
    
    # Get subscription summary
    $allResourceGroups = Get-AzResourceGroup
    $allResources = Get-AzResource
    
    Write-Output "--- Subscription Summary ---"
    Write-Output "Total Resource Groups: $($allResourceGroups.Count)"
    Write-Output "Total Resources: $($allResources.Count)"
    Write-Output ""
    
    # Group resources by type
    Write-Output "--- Top Resource Types ---"
    $resourcesByType = $allResources | 
        Group-Object ResourceType | 
        Sort-Object Count -Descending | 
        Select-Object -First 10
    
    foreach ($type in $resourcesByType) {
        Write-Output "  $($type.Name): $($type.Count)"
    }
    
    # Group resources by location
    Write-Output "`n--- Resources by Location ---"
    $resourcesByLocation = $allResources | 
        Group-Object Location | 
        Sort-Object Count -Descending
    
    foreach ($location in $resourcesByLocation) {
        Write-Output "  $($location.Name): $($location.Count) resources"
    }
    
    # Detailed resource group info
    Write-Output "`n--- Top $TopResourceGroups Resource Groups (by resource count) ---"
    $topRGs = $allResourceGroups | ForEach-Object {
        $rgName = $_.ResourceGroupName
        $rgResources = $allResources | Where-Object { $_.ResourceGroupName -eq $rgName }
        
        [PSCustomObject]@{
            Name          = $rgName
            Location      = $_.Location
            ResourceCount = $rgResources.Count
            Tags          = $_.Tags.Count
        }
    } | Sort-Object ResourceCount -Descending | Select-Object -First $TopResourceGroups
    
    foreach ($rg in $topRGs) {
        Write-Output "`n📦 $($rg.Name)"
        Write-Output "   Location: $($rg.Location)"
        Write-Output "   Resources: $($rg.ResourceCount)"
        Write-Output "   Tags: $($rg.Tags)"
    }
    
    # Cost insights
    Write-Output "`n--- Resource Analysis ---"
    $vmCount = ($allResources | Where-Object { $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' }).Count
    $storageCount = ($allResources | Where-Object { $_.ResourceType -like '*Storage*' }).Count
    $networkCount = ($allResources | Where-Object { $_.ResourceType -like '*Network*' }).Count
    
    Write-Output "Virtual Machines: $vmCount"
    Write-Output "Storage Accounts: $storageCount"
    Write-Output "Network Resources: $networkCount"
    
    Write-Output "`n=== Inventory Complete ==="
  EOT

  tags = var.tags
}

# Link runbook to PowerShell 7.4 runtime environment
resource "null_resource" "link_modern_query_runtime" {
  triggers = {
    runbook_id     = azurerm_automation_runbook.modern_query.id
    runtime_id     = null_resource.ps74_runtime.id
    packages       = join(",", keys(local.packages))
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method patch `
        --url "https://management.azure.com${azurerm_automation_runbook.modern_query.id}?api-version=2024-10-23" `
        --body '{\"properties\": {\"type\": \"PowerShell\", \"runtimeEnvironment\": \"ps74-runtime\"}}'
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_automation_runbook.modern_query,
    null_resource.runtime_packages
  ]
}

# ============================================================================
# Execute Test Runbooks
# ============================================================================

# Run all 3 runbooks to test PowerShell 7.4 runtime
resource "null_resource" "run_ps74_features" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      Write-Output "Starting PowerShell 7.4 Features Demo runbook..."
      az automation runbook start `
        --automation-account-name "${azurerm_automation_account.main.name}" `
        --resource-group "${azurerm_resource_group.main.name}" `
        --name "${azurerm_automation_runbook.ps74_features.name}"
      Write-Output "Job started for Demo-PowerShell74-Features"
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    null_resource.link_ps74_features_runtime
  ]
}

resource "null_resource" "run_parallel_processing" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      Write-Output "Starting Parallel Processing Demo runbook..."
      az automation runbook start `
        --automation-account-name "${azurerm_automation_account.main.name}" `
        --resource-group "${azurerm_resource_group.main.name}" `
        --name "${azurerm_automation_runbook.parallel_processing.name}"
      Write-Output "Job started for Demo-ParallelProcessing"
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    null_resource.link_parallel_processing_runtime,
    null_resource.run_ps74_features
  ]
}

resource "null_resource" "run_modern_query" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      Write-Output "Starting Azure Resource Inventory runbook..."
      az automation runbook start `
        --automation-account-name "${azurerm_automation_account.main.name}" `
        --resource-group "${azurerm_resource_group.main.name}" `
        --name "${azurerm_automation_runbook.modern_query.name}" `
        --parameters '{\"TopResourceGroups\":3}'
      Write-Output "Job started for Get-AzureResourceInventory"
      Write-Output ""
      Write-Output "All 3 runbooks have been started!"
      Write-Output "Check the Azure portal to view job output:"
      Write-Output "https://portal.azure.com/#@/resource${azurerm_automation_account.main.id}/jobs"
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    null_resource.link_modern_query_runtime,
    null_resource.run_parallel_processing
  ]
}
