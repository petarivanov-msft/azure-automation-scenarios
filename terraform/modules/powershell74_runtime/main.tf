# ============================================================================
# PowerShell 7.4 Runtime Module
# ============================================================================
# Creates PowerShell 7.4 runtime environment with modern features
# ============================================================================

# Create PowerShell 7.4 runtime environment using Azure CLI
resource "null_resource" "ps74_runtime" {
  triggers = {
    automation_account_id = var.automation_account_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      az rest --method PUT \
        --url "https://management.azure.com${var.automation_account_id}/runtimeEnvironments/ps74-runtime?api-version=2023-05-15-preview" \
        --body '{
          "properties": {
            "runtime": {
              "language": "PowerShell",
              "version": "7.4"
            },
            "defaultPackages": {
              "Az.Accounts": "3.0.4",
              "Az.Compute": "8.3.0",
              "Az.Storage": "7.3.0",
              "Az.Resources": "7.4.0",
              "Az.Monitor": "5.2.1"
            }
          }
        }'
    EOT
  }
}

# Demo runbooks showcasing PowerShell 7.4 features
resource "azurerm_automation_runbook" "ps74_features" {
  name                    = "Demo-PowerShell74-Features"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Demo-PowerShell74-Features.ps1")
  tags    = var.tags

  depends_on = [null_resource.ps74_runtime]
}

resource "azurerm_automation_runbook" "parallel_processing" {
  name                    = "Demo-ParallelProcessing"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Demo-ParallelProcessing.ps1")
  tags    = var.tags

  depends_on = [null_resource.ps74_runtime]
}

resource "azurerm_automation_runbook" "resource_inventory" {
  name                    = "Get-AzureResourceInventory"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = file("${path.module}/runbooks/Get-AzureResourceInventory.ps1")
  tags    = var.tags

  depends_on = [null_resource.ps74_runtime]
}
