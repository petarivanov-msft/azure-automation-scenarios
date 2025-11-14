<#
.SYNOPSIS
    Common functions shared between deployment and cleanup scripts
.DESCRIPTION
    This module provides reusable functions for Azure Automation scenario management.
    It includes UI functions, prerequisite checking, and scenario definitions.
.NOTES
    Version: 1.0
    Author: Azure Automation Demos
    Date: November 2025
#>

# ============================================================================
# Color and UI Functions
# ============================================================================

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-ColorOutput "║  $($Text.PadRight(70))  ║" -ForegroundColor Cyan
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning2 {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" -ForegroundColor Red
}

# ============================================================================
# Scenario Definitions
# ============================================================================

function Get-ScenarioDefinitions {
    param(
        [switch]$FullDetails
    )
    
    $scenarios = @(
        @{
            Number = 1
            Name = "Graph API Automation with Managed Identity"
            Directory = "01-graph-api-automation"
            Description = "Microsoft Graph API integration with Azure Automation"
            FullDescription = "Demonstrates Microsoft Graph API integration with Azure Automation using managed identities. Installs Graph SDK modules and grants permissions to read users, groups, and applications."
            DeployTime = "~5-7 minutes"
            Difficulty = "Intermediate"
        },
        @{
            Number = 2
            Name = "Start/Stop VMs with Tag-Based Scheduling"
            Directory = "02-startstop-vms"
            Description = "Automated VM power management with 3 test VMs"
            FullDescription = "Automated VM power management based on PowerSchedule tags. Includes 3 VMs with different schedules (AlwaysOn, BusinessHours, NightShutdown) and automated start/stop runbooks."
            DeployTime = "~8-10 minutes"
            Difficulty = "Beginner"
        },
        @{
            Number = 3
            Name = "PowerShell 7.4 Runtime Environment"
            Directory = "03-powershell74-runtime"
            Description = "PowerShell 7.4 features and runtime environment"
            FullDescription = "Showcases PowerShell 7.4 features in Azure Automation including runtime environments, modern syntax (ternary operators, null coalescing), parallel processing, and enhanced cmdlets."
            DeployTime = "~6-8 minutes"
            Difficulty = "Advanced"
        },
        @{
            Number = 4
            Name = "Hybrid Worker Lab Setup"
            Directory = "04-hybrid-worker-setup"
            Description = "Hybrid Worker with Windows VM and test runbook"
            FullDescription = "Complete Hybrid Worker environment with Windows VM, Hybrid Worker Extension, managed identities, and test runbook. Demonstrates running automation outside Azure."
            DeployTime = "~7-10 minutes"
            Difficulty = "Intermediate"
        }
    )
    
    if ($FullDetails) {
        return $scenarios
    } else {
        return $scenarios | Select-Object Number, Name, Directory, Description
    }
}

# ============================================================================
# Prerequisite Checking
# ============================================================================

function Test-Prerequisites {
    param(
        [switch]$Detailed
    )
    
    Write-Info "Checking prerequisites..."
    
    $terraformInstalled = Get-Command terraform -ErrorAction SilentlyContinue
    $azInstalled = Get-Command az -ErrorAction SilentlyContinue
    
    $allMet = $true
    
    if (-not $terraformInstalled) {
        Write-ErrorMsg "Terraform is not installed or not in PATH"
        Write-Info "Download from: https://www.terraform.io/downloads"
        $allMet = $false
    } elseif ($Detailed) {
        $tfVersion = terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version
        Write-Success "Terraform is installed (v$tfVersion)"
    }
    
    if (-not $azInstalled) {
        Write-ErrorMsg "Azure CLI is not installed or not in PATH"
        Write-Info "Download from: https://docs.microsoft.com/cli/azure/install-azure-cli"
        $allMet = $false
    } elseif ($Detailed) {
        Write-Success "Azure CLI is installed"
    }
    
    if ($allMet -and -not $Detailed) {
        Write-Success "All prerequisites are met"
    }
    
    return $allMet
}

# ============================================================================
# Azure Subscription Helpers
# ============================================================================

function Get-AzureSubscriptionInfo {
    Write-Info "Checking Azure authentication..."
    
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($null -ne $account) {
            Write-Success "Logged into Azure"
            Write-Info "Subscription: $($account.name)"
            Write-Info "Subscription ID: $($account.id)"
            Write-Info "Tenant: $($account.tenantId)"
            return $account
        }
    } catch {
        Write-Warning2 "Not logged into Azure or session expired"
        Write-Info "Running 'az login' to authenticate..."
        az login
        return Get-AzureSubscriptionInfo
    }
    
    return $null
}

# ============================================================================
# Scenario Display Helpers
# ============================================================================

function Show-ScenarioMenu {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Scenarios,
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    Write-Header $Title
    
    foreach ($scenario in $Scenarios) {
        Write-ColorOutput "[$($scenario.Number)] $($scenario.Name)" -ForegroundColor Yellow
        Write-ColorOutput "    📁 Directory: $($scenario.Directory)" -ForegroundColor Gray
        Write-ColorOutput "    📝 $($scenario.Description)" -ForegroundColor Gray
        
        if ($scenario.DeployTime) {
            Write-ColorOutput "    ⏱️  Deploy Time: $($scenario.DeployTime) | 🎯 Difficulty: $($scenario.Difficulty)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-ColorOutput "[0] Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Get-ScenarioSelection {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Scenarios
    )
    
    do {
        $selection = Read-Host "Enter your choice (0-$($Scenarios.Count))"
        $valid = $selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -le $Scenarios.Count
        
        if (-not $valid) {
            Write-Warning2 "Invalid selection. Please enter a number between 0 and $($Scenarios.Count)"
        }
    } while (-not $valid)
    
    return [int]$selection
}

# ============================================================================
# Functions are now available in the calling script's scope
# ============================================================================
# No Export-ModuleMember needed for .ps1 script files
# All functions defined above are automatically available when dot-sourced
