<#
.SYNOPSIS
    Interactive cleanup script for Azure Automation Demo Scenarios
.DESCRIPTION
    This script scans for deployed scenarios and provides an interactive menu to destroy them.
    It identifies deployed scenarios by checking for .terraform directories.
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
        Description = "Microsoft Graph API integration with Azure Automation"
    },
    @{
        Number = 2
        Name = "Start/Stop VMs with Tag-Based Scheduling"
        Directory = "02-startstop-vms"
        Description = "Automated VM power management with 3 test VMs"
    },
    @{
        Number = 3
        Name = "PowerShell 7.4 Runtime Environment"
        Directory = "03-powershell74-runtime"
        Description = "PowerShell 7.4 features and runtime environment"
    },
    @{
        Number = 4
        Name = "Hybrid Worker Lab Setup"
        Directory = "04-hybrid-worker-setup"
        Description = "Hybrid Worker with Windows VM and test runbook"
    }
)

# ============================================================================
# Helper Functions
# ============================================================================

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $terraformInstalled = Get-Command terraform -ErrorAction SilentlyContinue
    $azInstalled = Get-Command az -ErrorAction SilentlyContinue
    
    if (-not $terraformInstalled) {
        Write-ErrorMsg "Terraform is not installed or not in PATH"
        Write-Info "Download from: https://www.terraform.io/downloads"
        return $false
    }
    
    if (-not $azInstalled) {
        Write-ErrorMsg "Azure CLI is not installed or not in PATH"
        Write-Info "Download from: https://docs.microsoft.com/cli/azure/install-azure-cli"
        return $false
    }
    
    Write-Success "Terraform: $(terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version)"
    Write-Success "Azure CLI: $(az version --query '\"azure-cli\"' -o tsv)"
    
    return $true
}

function Get-DeployedScenarios {
    Write-Info "Scanning for deployed scenarios..."
    Write-Host ""
    
    $deployed = @()
    
    foreach ($scenario in $scenarios) {
        $scenarioPath = Join-Path $PSScriptRoot $scenario.Directory
        $terraformPath = Join-Path $scenarioPath ".terraform"
        
        if (Test-Path $terraformPath) {
            $deployed += $scenario
            Write-ColorOutput "  ✓ Scenario $($scenario.Number): $($scenario.Name)" -ForegroundColor Green
        } else {
            Write-ColorOutput "  ○ Scenario $($scenario.Number): Not deployed" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    return $deployed
}

function Show-DestroyMenu {
    param($DeployedScenarios)
    
    Clear-Host
    Write-Header "Azure Automation Demos - Cleanup Tool"
    
    if ($DeployedScenarios.Count -eq 0) {
        Write-Info "No deployed scenarios found!"
        Write-Host ""
        Write-ColorOutput "All scenarios appear to be cleaned up already." -ForegroundColor Green
        Write-Host ""
        Write-Info "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        return $null
    }
    
    Write-ColorOutput "Found $($DeployedScenarios.Count) deployed scenario(s):" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $DeployedScenarios.Count; $i++) {
        $scenario = $DeployedScenarios[$i]
        Write-ColorOutput "  [$($i + 1)] Scenario $($scenario.Number): $($scenario.Name)" -ForegroundColor Cyan
        Write-ColorOutput "      📁 $($scenario.Directory)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-ColorOutput "  [A] Destroy ALL scenarios" -ForegroundColor Yellow
    Write-ColorOutput "  [0] Exit" -ForegroundColor Gray
    Write-Host ""
    
    return $DeployedScenarios
}

function Get-DestroyChoice {
    param($DeployedScenarios)
    
    $validChoices = @('0', 'A')
    for ($i = 1; $i -le $DeployedScenarios.Count; $i++) {
        $validChoices += $i.ToString()
    }
    
    while ($true) {
        $choice = Read-Host "Select scenario to destroy (or 0 to exit)"
        
        if ($validChoices -contains $choice.ToUpper()) {
            return $choice.ToUpper()
        }
        
        Write-Warning2 "Invalid choice. Please try again."
    }
}

function Confirm-Destruction {
    param($Scenario)
    
    Write-Host ""
    Write-Warning2 "═══════════════════════════════════════════════════════════════════════"
    Write-Warning2 "  WARNING: This will PERMANENTLY DELETE all resources!"
    Write-Warning2 "═══════════════════════════════════════════════════════════════════════"
    Write-Host ""
    Write-ColorOutput "  Scenario: $($Scenario.Name)" -ForegroundColor Yellow
    Write-ColorOutput "  Directory: $($Scenario.Directory)" -ForegroundColor Yellow
    Write-Host ""
    Write-Warning2 "This action cannot be undone!"
    Write-Host ""
    
    $confirm = Read-Host "Type 'yes' to confirm destruction"
    
    return ($confirm -eq "yes")
}

function Destroy-Scenario {
    param($Scenario)
    
    $scenarioPath = Join-Path $PSScriptRoot $Scenario.Directory
    
    if (-not (Test-Path $scenarioPath)) {
        Write-ErrorMsg "Scenario directory not found: $scenarioPath"
        return $false
    }
    
    Write-Header "Destroying Scenario $($Scenario.Number)"
    
    Push-Location $scenarioPath
    
    try {
        if (-not (Test-Path ".terraform")) {
            Write-Warning2 "Scenario not initialized. Nothing to destroy."
            return $true
        }
        
        Write-Info "Running Terraform destroy..."
        Write-Host ""
        Write-ColorOutput "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        
        terraform destroy -auto-approve
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Terraform destroy failed"
            return $false
        }
        
        Write-Host ""
        Write-Success "Resources destroyed successfully!"
        Write-Host ""
        
        # Optionally remove .terraform directory
        Write-Info "Cleaning up Terraform state..."
        Remove-Item -Path ".terraform" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path ".terraform.lock.hcl" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "terraform.tfstate*" -Force -ErrorAction SilentlyContinue
        Write-Success "Local Terraform files cleaned up"
        Write-Host ""
        
        return $true
        
    } catch {
        Write-ErrorMsg "An error occurred during destruction: $_"
        return $false
    } finally {
        Pop-Location
    }
}

function Show-CompletionMessage {
    param($Success)
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    if ($Success) {
        Write-Success "Cleanup completed successfully!"
        Write-Host ""
        Write-Info "All selected resources have been removed from Azure"
    } else {
        Write-Warning2 "Cleanup completed with errors"
        Write-Host ""
        Write-Info "Some resources may still exist. Check Azure Portal to verify."
    }
    
    Write-ColorOutput "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# Main Function
# ============================================================================

function Main {
    Clear-Host
    Write-Header "Azure Automation Demos - Cleanup Tool"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-Info "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        return
    }
    
    Write-Host ""
    
    while ($true) {
        # Scan for deployed scenarios
        $deployed = Get-DeployedScenarios
        
        # Show menu
        $deployedScenarios = Show-DestroyMenu -DeployedScenarios $deployed
        
        if ($null -eq $deployedScenarios) {
            return
        }
        
        # Get user choice
        $choice = Get-DestroyChoice -DeployedScenarios $deployedScenarios
        
        # Handle exit
        if ($choice -eq "0") {
            Write-Info "Exiting cleanup tool..."
            return
        }
        
        # Handle destroy all
        if ($choice -eq "A") {
            Write-Host ""
            Write-Warning2 "You are about to destroy ALL $($deployedScenarios.Count) deployed scenarios!"
            Write-Host ""
            $confirmAll = Read-Host "Type 'yes' to destroy all scenarios"
            
            if ($confirmAll -ne "yes") {
                Write-Info "Operation cancelled"
                Start-Sleep -Seconds 2
                continue
            }
            
            $allSuccess = $true
            foreach ($scenario in $deployedScenarios) {
                $success = Destroy-Scenario -Scenario $scenario
                if (-not $success) {
                    $allSuccess = $false
                }
                Write-Host ""
            }
            
            Show-CompletionMessage -Success $allSuccess
            Write-Info "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            continue
        }
        
        # Handle single scenario destruction
        $scenarioIndex = [int]$choice - 1
        $selectedScenario = $deployedScenarios[$scenarioIndex]
        
        # Confirm destruction
        if (-not (Confirm-Destruction -Scenario $selectedScenario)) {
            Write-Info "Operation cancelled"
            Start-Sleep -Seconds 2
            continue
        }
        
        # Destroy scenario
        $success = Destroy-Scenario -Scenario $selectedScenario
        
        Show-CompletionMessage -Success $success
        Write-Info "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

# ============================================================================
# Execute
# ============================================================================

Main
