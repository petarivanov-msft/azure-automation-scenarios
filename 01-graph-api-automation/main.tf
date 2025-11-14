# ============================================================================
# Azure Automation - Microsoft Graph API Automation
# ============================================================================
# This configuration deploys:
# - Azure Automation Account with Microsoft.Graph PowerShell module
# - Managed Identity with Microsoft Graph API permissions
# - Sample runbooks using Graph API to query users, groups, and applications
# - Automated runbook execution for testing
#
# Azure Cloud Shell Compatible: Works in both PowerShell and Bash modes
# Requires: Terraform 1.5+, Azure CLI authentication
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
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

provider "azuread" {}

# ============================================================================
# Data Sources
# ============================================================================

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.resource_prefix}-graph-automation"
  location = var.location
  tags     = var.tags
}

# ============================================================================
# Azure Automation Account
# ============================================================================

resource "azurerm_automation_account" "main" {
  name                = "${var.resource_prefix}-automation-graph"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ============================================================================
# PowerShell Modules for Microsoft Graph
# ============================================================================

# Microsoft.Graph.Authentication module (required first)
resource "azurerm_automation_module" "graph_authentication" {
  name                    = "Microsoft.Graph.Authentication"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Microsoft.Graph.Authentication/2.11.1"
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "10m"
  }
}

# Microsoft.Graph.Users module
resource "azurerm_automation_module" "graph_users" {
  name                    = "Microsoft.Graph.Users"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Microsoft.Graph.Users/2.11.1"
  }

  depends_on = [azurerm_automation_module.graph_authentication]
}

# Microsoft.Graph.Groups module
resource "azurerm_automation_module" "graph_groups" {
  name                    = "Microsoft.Graph.Groups"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Microsoft.Graph.Groups/2.11.1"
  }

  depends_on = [azurerm_automation_module.graph_authentication]
}

# Microsoft.Graph.Applications module
resource "azurerm_automation_module" "graph_applications" {
  name                    = "Microsoft.Graph.Applications"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Microsoft.Graph.Applications/2.11.1"
  }

  depends_on = [azurerm_automation_module.graph_authentication]
}

# ============================================================================
# Grant Microsoft Graph API Permissions to Managed Identity
# ============================================================================

# Get Microsoft Graph Service Principal
data "azuread_service_principal" "msgraph" {
  display_name = "Microsoft Graph"
}

# Grant User.Read.All permission (read all users)
resource "azuread_app_role_assignment" "graph_users_read" {
  app_role_id         = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
  principal_object_id = azurerm_automation_account.main.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant Group.Read.All permission (read all groups)
resource "azuread_app_role_assignment" "graph_groups_read" {
  app_role_id         = "5b567255-7703-4780-807c-7be8301ae99b" # Group.Read.All
  principal_object_id = azurerm_automation_account.main.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant Application.Read.All permission (read all applications)
resource "azuread_app_role_assignment" "graph_applications_read" {
  app_role_id         = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30" # Application.Read.All
  principal_object_id = azurerm_automation_account.main.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant Directory.Read.All permission (read directory data)
resource "azuread_app_role_assignment" "graph_directory_read" {
  app_role_id         = "7ab1d382-f21e-4acd-a863-ba3e13f7da61" # Directory.Read.All
  principal_object_id = azurerm_automation_account.main.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# ============================================================================
# Runbook 1: Get Users Report
# ============================================================================

resource "azurerm_automation_runbook" "get_users" {
  name                    = "Get-UsersReport"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Retrieves user information from Microsoft Graph API
    .DESCRIPTION
        Uses managed identity to connect to Microsoft Graph and retrieve users
        Demonstrates User.Read.All permission usage
    #>
    
    param(
        [int]$TopCount = 10
    )
    
    Write-Output "Starting Get-UsersReport runbook..."
    Write-Output "Connecting to Microsoft Graph using Managed Identity..."
    
    try {
        # Connect using managed identity
        Connect-MgGraph -Identity -NoWelcome
        
        Write-Output "Successfully connected to Microsoft Graph"
        Write-Output "Current context: $(Get-MgContext | Select-Object -ExpandProperty Account)"
        
        Write-Output "`nRetrieving top $TopCount users..."
        
        # Get users from Microsoft Graph
        $users = Get-MgUser -Top $TopCount -Property DisplayName,UserPrincipalName,Mail,AccountEnabled,CreatedDateTime,UserType -Sort DisplayName
        
        Write-Output "`nFound $($users.Count) users:"
        Write-Output "=" * 80
        
        foreach ($user in $users) {
            Write-Output "`nDisplay Name: $($user.DisplayName)"
            Write-Output "UPN: $($user.UserPrincipalName)"
            Write-Output "Email: $($user.Mail)"
            Write-Output "Account Enabled: $($user.AccountEnabled)"
            Write-Output "User Type: $($user.UserType)"
            Write-Output "Created: $($user.CreatedDateTime)"
            Write-Output "-" * 80
        }
        
        Write-Output "`nTotal users retrieved: $($users.Count)"
        Write-Output "Runbook completed successfully!"
        
    } catch {
        Write-Error "Error occurred: $_"
        Write-Error $_.Exception.Message
        throw
    } finally {
        # Disconnect from Graph
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.graph_authentication,
    azurerm_automation_module.graph_users,
    azuread_app_role_assignment.graph_users_read
  ]
}

# ============================================================================
# Runbook 2: Get Groups Report
# ============================================================================

resource "azurerm_automation_runbook" "get_groups" {
  name                    = "Get-GroupsReport"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Retrieves group information from Microsoft Graph API
    .DESCRIPTION
        Uses managed identity to connect to Microsoft Graph and retrieve groups
        Demonstrates Group.Read.All permission usage
    #>
    
    param(
        [int]$TopCount = 10,
        [string]$GroupType = "All"  # All, Security, Microsoft365
    )
    
    Write-Output "Starting Get-GroupsReport runbook..."
    Write-Output "Parameters: TopCount=$TopCount, GroupType=$GroupType"
    
    try {
        # Connect using managed identity
        Connect-MgGraph -Identity -NoWelcome
        Write-Output "Successfully connected to Microsoft Graph"
        
        Write-Output "`nRetrieving groups..."
        
        # Get groups from Microsoft Graph
        $groups = Get-MgGroup -Top $TopCount -Property DisplayName,Description,GroupTypes,CreatedDateTime,SecurityEnabled,MailEnabled -Sort DisplayName
        
        # Filter by group type if specified
        if ($GroupType -eq "Security") {
            $groups = $groups | Where-Object { $_.SecurityEnabled -eq $true -and $_.MailEnabled -eq $false }
        } elseif ($GroupType -eq "Microsoft365") {
            $groups = $groups | Where-Object { $_.GroupTypes -contains "Unified" }
        }
        
        Write-Output "`nFound $($groups.Count) groups:"
        Write-Output "=" * 80
        
        foreach ($group in $groups) {
            Write-Output "`nGroup Name: $($group.DisplayName)"
            Write-Output "Description: $($group.Description)"
            
            if ($group.GroupTypes -contains "Unified") {
                Write-Output "Type: Microsoft 365 Group"
            } elseif ($group.SecurityEnabled) {
                Write-Output "Type: Security Group"
            } else {
                Write-Output "Type: Distribution Group"
            }
            
            Write-Output "Security Enabled: $($group.SecurityEnabled)"
            Write-Output "Mail Enabled: $($group.MailEnabled)"
            Write-Output "Created: $($group.CreatedDateTime)"
            
            # Get member count
            try {
                $memberCount = (Get-MgGroupMember -GroupId $group.Id -Top 1 -CountVariable memberCountVar -ConsistencyLevel eventual).Count
                Write-Output "Members: $memberCount"
            } catch {
                Write-Output "Members: Unable to retrieve"
            }
            
            Write-Output "-" * 80
        }
        
        Write-Output "`nTotal groups retrieved: $($groups.Count)"
        Write-Output "Runbook completed successfully!"
        
    } catch {
        Write-Error "Error occurred: $_"
        Write-Error $_.Exception.Message
        throw
    } finally {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.graph_authentication,
    azurerm_automation_module.graph_groups,
    azuread_app_role_assignment.graph_groups_read
  ]
}

# ============================================================================
# Runbook 3: Get Applications Report
# ============================================================================

resource "azurerm_automation_runbook" "get_applications" {
  name                    = "Get-ApplicationsReport"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Retrieves application registrations from Microsoft Graph API
    .DESCRIPTION
        Uses managed identity to connect to Microsoft Graph and retrieve app registrations
        Demonstrates Application.Read.All permission usage
    #>
    
    param(
        [int]$TopCount = 10
    )
    
    Write-Output "Starting Get-ApplicationsReport runbook..."
    
    try {
        # Connect using managed identity
        Connect-MgGraph -Identity -NoWelcome
        Write-Output "Successfully connected to Microsoft Graph"
        
        Write-Output "`nRetrieving top $TopCount applications..."
        
        # Get applications from Microsoft Graph
        $apps = Get-MgApplication -Top $TopCount -Property DisplayName,AppId,CreatedDateTime,SignInAudience,PublisherDomain -Sort DisplayName
        
        Write-Output "`nFound $($apps.Count) applications:"
        Write-Output "=" * 80
        
        foreach ($app in $apps) {
            Write-Output "`nApplication Name: $($app.DisplayName)"
            Write-Output "Application ID: $($app.AppId)"
            Write-Output "Publisher Domain: $($app.PublisherDomain)"
            Write-Output "Sign-in Audience: $($app.SignInAudience)"
            Write-Output "Created: $($app.CreatedDateTime)"
            Write-Output "-" * 80
        }
        
        Write-Output "`nTotal applications retrieved: $($apps.Count)"
        Write-Output "Runbook completed successfully!"
        
    } catch {
        Write-Error "Error occurred: $_"
        Write-Error $_.Exception.Message
        throw
    } finally {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
  EOT

  tags = var.tags

  depends_on = [
    azurerm_automation_module.graph_authentication,
    azurerm_automation_module.graph_applications,
    azuread_app_role_assignment.graph_applications_read
  ]
}

# ============================================================================
# Test Runbooks Manually
# ============================================================================
# Auto-testing removed for cross-platform compatibility
# Test runbooks manually via Azure Portal or Azure CLI:
#
# Example commands:
# az automation runbook start --automation-account-name "<account>" --resource-group "<rg>" --name "Get-UsersReport" --parameters TopCount=5
# az automation runbook start --automation-account-name "<account>" --resource-group "<rg>" --name "Get-GroupsReport" --parameters TopCount=10 GroupType=Security
# az automation runbook start --automation-account-name "<account>" --resource-group "<rg>" --name "Get-ApplicationsReport" --parameters TopCount=10
