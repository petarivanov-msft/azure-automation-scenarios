<#
.SYNOPSIS
    Format and validate all Terraform configurations
.DESCRIPTION
    This script runs terraform fmt on all scenario directories to ensure consistent formatting.
    It's useful for maintainers to ensure code quality before committing.
.NOTES
    Version: 1.0
    Author: Azure Automation Demos
    Date: November 2025
#>

# Import common functions for consistent output
. (Join-Path $PSScriptRoot "common-functions.ps1")

Write-Header "Terraform Format & Validation Tool"

# Get all scenario directories
$scenarioDirs = Get-ChildItem -Path $PSScriptRoot -Directory | Where-Object {
    $_.Name -match '^\d{2}-'
}

if ($scenarioDirs.Count -eq 0) {
    Write-ErrorMsg "No scenario directories found!"
    exit 1
}

Write-Info "Found $($scenarioDirs.Count) scenario directories"
Write-Host ""

$totalFormatted = 0
$totalErrors = 0

foreach ($dir in $scenarioDirs) {
    Write-ColorOutput "Processing: $($dir.Name)" -ForegroundColor Cyan
    
    Push-Location $dir.FullName
    
    try {
        # Check for Terraform files
        $tfFiles = Get-ChildItem -Filter "*.tf"
        if ($tfFiles.Count -eq 0) {
            Write-Warning2 "  No Terraform files found, skipping..."
            Pop-Location
            continue
        }
        
        Write-Info "  Found $($tfFiles.Count) Terraform files"
        
        # Run terraform fmt
        Write-Info "  Running terraform fmt..."
        $fmtOutput = terraform fmt -check -diff 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "  All files properly formatted"
        } elseif ($LASTEXITCODE -eq 3) {
            # Exit code 3 means files were reformatted
            Write-Warning2 "  Some files were reformatted:"
            $fmtOutput | ForEach-Object { Write-Host "    $_" }
            
            # Actually format the files
            terraform fmt | Out-Null
            $totalFormatted++
            Write-Success "  Files reformatted successfully"
        } else {
            Write-ErrorMsg "  Error running terraform fmt"
            $totalErrors++
        }
        
        # Optionally validate (requires init)
        if (Test-Path ".terraform") {
            Write-Info "  Running terraform validate..."
            terraform validate -no-color 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  Configuration is valid"
            } else {
                Write-Warning2 "  Validation warnings (may need terraform init)"
            }
        }
        
    } catch {
        Write-ErrorMsg "  Error: $_"
        $totalErrors++
    } finally {
        Pop-Location
    }
    
    Write-Host ""
}

# Summary
Write-Header "Summary"

if ($totalFormatted -eq 0 -and $totalErrors -eq 0) {
    Write-Success "All Terraform configurations are properly formatted!"
} else {
    if ($totalFormatted -gt 0) {
        Write-Info "Formatted $totalFormatted scenario(s)"
    }
    if ($totalErrors -gt 0) {
        Write-ErrorMsg "Encountered errors in $totalErrors scenario(s)"
    }
}

Write-Host ""
Write-Info "Done!"
