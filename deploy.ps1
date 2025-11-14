<#
.SYNOPSIS
    Interactive deployment script for Azure Automation Demo Scenarios
.DESCRIPTION
    This script provides an interactive menu to deploy any of the 4 Azure Automation scenarios.
    Each scenario demonstrates different Azure Automation capabilities using Terraform.
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

$scenarios = @(
    @{
        Number = 1
        Name = "Graph API Automation with Managed Identity"
        Directory = "01-graph-api-automation"
        Description = "Demonstrates Microsoft Graph API integration with Azure Automation using managed identities. Installs Graph SDK modules and grants permissions to read users, groups, and applications."
        DeployTime = "~5-7 minutes"
        Difficulty = "Intermediate"
    },
    @{
        Number = 2
        Name = "Start/Stop VMs with Tag-Based Scheduling"
        Directory = "02-startstop-vms"
        Description = "Automated VM power management based on PowerSchedule tags. Includes 3 VMs with different schedules (AlwaysOn, BusinessHours, NightShutdown) and automated start/stop runbooks."
        DeployTime = "~8-10 minutes"
        Difficulty = "Beginner"
    },
    @{
        Number = 3
        Name = "PowerShell 7.4 Runtime Environment"
        Directory = "03-powershell74-runtime"
        Description = "Showcases PowerShell 7.4 features in Azure Automation including runtime environments, modern syntax (ternary operators, null coalescing), parallel processing, and enhanced cmdlets."
        DeployTime = "~6-8 minutes"
        Difficulty = "Advanced"
    },
    @{
        Number = 4
        Name = "Hybrid Worker Lab Setup"
        Directory = "04-hybrid-worker-setup"
        Description = "Complete Hybrid Worker environment with Windows VM, Hybrid Worker Extension, managed identities, and test runbook. Demonstrates running automation outside Azure."
        DeployTime = "~7-10 minutes"
        Difficulty = "Intermediate"
    }
)

# ============================================================================
# Helper Functions
# ============================================================================

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $missingTools = @()
    
    # Check Terraform
    try {
        $tfVersion = terraform version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Terraform is installed"
        } else {
            $missingTools += "Terraform"
        }
    } catch {
        $missingTools += "Terraform"
    }
    
    # Check Azure CLI
    try {
        $azVersion = az version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Azure CLI is installed"
        } else {
            $missingTools += "Azure CLI"
        }
    } catch {
        $missingTools += "Azure CLI"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-ErrorMsg "Missing required tools: $($missingTools -join ', ')"
        Write-Info "Please install the missing tools and try again"
        return $false
    }
    
    Write-Success "All prerequisites are met"
    return $true
}

function Show-MainMenu {
    Clear-Host
    Write-Header "Azure Automation Demo Scenarios"
    
    Write-ColorOutput "Select a scenario to deploy:" -ForegroundColor White
    Write-Host ""
    
    foreach ($scenario in $scenarios) {
        Write-ColorOutput "  [$($scenario.Number)]" -ForegroundColor Yellow
        Write-ColorOutput "    📌 $($scenario.Name)" -ForegroundColor Cyan
        Write-ColorOutput "    📖 $($scenario.Description)" -ForegroundColor White
        Write-ColorOutput "    ⏱️  Deploy Time: $($scenario.DeployTime)" -ForegroundColor Gray
        Write-ColorOutput "    💰 Cost: $($scenario.Cost)" -ForegroundColor Gray
        Write-ColorOutput "    📊 Difficulty: $($scenario.Difficulty)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-ColorOutput "  [0] Exit" -ForegroundColor Red
    Write-Host ""
}

function Get-ScenarioChoice {
    $choice = Read-Host "Enter your choice (0-4)"
    
    if ($choice -eq "0") {
        Write-ColorOutput "`nGoodbye! 👋" -ForegroundColor Cyan
        exit 0
    }
    
    $selectedScenario = $scenarios | Where-Object { $_.Number -eq [int]$choice }
    
    if ($null -eq $selectedScenario) {
        Write-ErrorMsg "Invalid choice. Please select 0-4."
        Start-Sleep -Seconds 2
        return $null
    }
    
    return $selectedScenario
}

function Show-ScenarioDetails {
    param($Scenario)
    
    Clear-Host
    Write-Header "Scenario $($Scenario.Number): $($Scenario.Name)"
    
    Write-ColorOutput "📖 Description:" -ForegroundColor Cyan
    Write-Host "   $($Scenario.Description)"
    Write-Host ""
    
    Write-ColorOutput "⏱️  Estimated Deploy Time: $($Scenario.DeployTime)" -ForegroundColor Yellow
    Write-ColorOutput "📊 Difficulty Level: $($Scenario.Difficulty)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-ColorOutput "📁 Scenario Directory: $($Scenario.Directory)" -ForegroundColor Gray
    Write-Host ""
}

function Confirm-Deployment {
    param($Scenario)
    
    # Get current subscription info
    try {
        $subInfo = az account show --query "{name:name, id:id}" -o json 2>$null | ConvertFrom-Json
        if ($subInfo) {
            Write-Host ""
            Write-ColorOutput "Target Azure Subscription:" -ForegroundColor Cyan
            Write-ColorOutput "  Name: $($subInfo.name)" -ForegroundColor White
            Write-ColorOutput "  ID:   $($subInfo.id)" -ForegroundColor White
            Write-Host ""
        }
    } catch {
        # If we can't get subscription info, continue anyway
    }
    
    Write-Warning2 "This will deploy resources to your Azure subscription."
    Write-Host ""
    
    $confirm = Read-Host "Do you want to proceed with deployment? (y/N)"
    
    return ($confirm -eq "y" -or $confirm -eq "Y")
}

function Deploy-Scenario {
    param($Scenario)
    
    $scenarioPath = Join-Path $PSScriptRoot $Scenario.Directory
    
    if (-not (Test-Path $scenarioPath)) {
        Write-ErrorMsg "Scenario directory not found: $scenarioPath"
        return $false
    }
    
    Write-Header "Deploying Scenario $($Scenario.Number)"
    
    Push-Location $scenarioPath
    
    try {
        # Check if already initialized
        if (-not (Test-Path ".terraform")) {
            Write-Info "Initializing Terraform..."
            terraform init
            
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMsg "Terraform initialization failed"
                return $false
            }
            Write-Success "Terraform initialized successfully"
        } else {
            Write-Info "Terraform already initialized"
        }
        
        Write-Host ""
        Write-Info "Running Terraform Plan..."
        Write-Host ""
        terraform plan | Out-Host
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Terraform plan failed"
            return $false
        }
        
        Write-Host ""
        Write-Info "Starting deployment..."
        Write-Info "This may take $($Scenario.DeployTime). Watch the output below for progress..."
        Write-Host ""
        Write-ColorOutput "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        
        terraform apply -auto-approve | Out-Host
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Terraform apply failed"
            return $false
        }
        
        Write-Host ""
        Write-Success "Deployment completed successfully!"
        Write-Host ""
        
        return $true
        
    } catch {
        Write-ErrorMsg "An error occurred during deployment: $_"
        return $false
    } finally {
        Pop-Location
    }
}

function Show-PostDeployment {
    param($Scenario)
    
    Write-Header "Deployment Summary"
    
    Write-Success "Scenario $($Scenario.Number) has been deployed successfully!"
    Write-Host ""
    
    Write-ColorOutput "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Review the outputs above for resource details and portal links"
    Write-Host "   2. Test the scenario functionality (see README.md for test commands)"
    Write-Host "   3. Explore the deployed resources in Azure Portal"
    Write-Host ""
    
    Write-ColorOutput "🧹 Important Reminder:" -ForegroundColor Yellow
    Write-Host "   When you're done testing, remember to clean up resources to avoid charges:"
    Write-Host "   cd $($Scenario.Directory)"
    Write-Host "   terraform destroy -auto-approve"
    Write-Host ""
    
    Write-ColorOutput "📚 Documentation:" -ForegroundColor Cyan
    Write-Host "   See $($Scenario.Directory)/README.md for detailed information"
    Write-Host ""
}

# ============================================================================
# Main Script
# ============================================================================

function Main {
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-Info "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-Host ""
    Write-Info "Press any key to continue to the main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Main menu loop
    while ($true) {
        Show-MainMenu
        
        $selectedScenario = Get-ScenarioChoice
        
        if ($null -eq $selectedScenario) {
            continue
        }
        
        Show-ScenarioDetails -Scenario $selectedScenario
        
        if (-not (Confirm-Deployment -Scenario $selectedScenario)) {
            Write-Info "Deployment cancelled by user"
            Start-Sleep -Seconds 2
            continue
        }
        
        $deploymentSuccess = Deploy-Scenario -Scenario $selectedScenario
        
        if ($deploymentSuccess) {
            Show-PostDeployment -Scenario $selectedScenario
        } else {
            Write-Host ""
            Write-ErrorMsg "═══════════════════════════════════════════════════════════════════════"
            Write-ErrorMsg "Deployment failed. Please review the errors above."
            Write-ErrorMsg "═══════════════════════════════════════════════════════════════════════"
            Write-Host ""
            Write-Info "Common issues:"
            Write-Host "  • Scenario 1: Requires Privileged Administrator role in Entra ID"
            Write-Host "  • Check subscription permissions (Contributor role needed)"
            Write-Host "  • Verify Terraform and Azure CLI are working correctly"
            Write-Host ""
        }
        
        Write-Info "Press any key to return to the main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Run the main function
Main
