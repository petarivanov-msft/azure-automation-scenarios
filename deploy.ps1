<#
.SYNOPSIS
    Interactive deployment script for Azure Automation Demo Scenarios
.DESCRIPTION
    This script provides an interactive menu to deploy any of the 4 Azure Automation scenarios.
    Each scenario demonstrates different Azure Automation capabilities using Terraform.
.NOTES
    Version: 1.1
    Author: Azure Automation Demos
    Date: November 2025
#>

# Import common functions
. (Join-Path $PSScriptRoot "common-functions.ps1")

# Get scenario definitions with full details
$scenarios = Get-ScenarioDefinitions -FullDetails

# ============================================================================
# Deployment-Specific Helper Functions
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Show-ScenarioMenu -Scenarios $scenarios -Title "Azure Automation Demo Scenarios - Deploy"
}

function Get-ScenarioChoice {
    $choice = Get-ScenarioSelection -Scenarios $scenarios
    
    if ($choice -eq 0) {
        Write-ColorOutput "`nGoodbye! 👋" -ForegroundColor Cyan
        exit 0
    }
    
    return $scenarios | Where-Object { $_.Number -eq $choice }
}

function Show-ScenarioDetails {
    param($Scenario)
    
    Clear-Host
    Write-Header "Scenario $($Scenario.Number): $($Scenario.Name)"
    
    Write-ColorOutput "📖 Description:" -ForegroundColor Cyan
    Write-Host "   $($Scenario.FullDescription)"
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
    $subInfo = Get-AzureSubscriptionInfo
    
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
