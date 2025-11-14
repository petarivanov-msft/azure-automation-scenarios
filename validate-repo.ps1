<#
.SYNOPSIS
    Repository health check script
.DESCRIPTION
    Validates the repository structure, checks for common issues, and ensures
    all scenarios are properly configured.
.NOTES
    Version: 1.0
    Author: Azure Automation Demos
    Date: November 2025
#>

# Import common functions
. (Join-Path $PSScriptRoot "common-functions.ps1")

Write-Header "Repository Health Check"

$issues = @()
$warnings = @()
$checks = 0

function Test-ScenarioStructure {
    param($ScenarioDir)
    
    $checks++
    $requiredFiles = @('main.tf', 'variables.tf', 'outputs.tf', 'README.md')
    $missing = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $ScenarioDir $file
        if (-not (Test-Path $filePath)) {
            $missing += $file
        }
    }
    
    if ($missing.Count -gt 0) {
        $issues += "Scenario '$($ScenarioDir.Name)' is missing: $($missing -join ', ')"
        return $false
    }
    
    return $true
}

function Test-GitIgnore {
    $checks++
    $gitignorePath = Join-Path $PSScriptRoot ".gitignore"
    
    if (-not (Test-Path $gitignorePath)) {
        $issues += "Missing .gitignore file"
        return $false
    }
    
    $content = Get-Content $gitignorePath -Raw
    
    # Check for important patterns
    $patterns = @('*.tfstate', '*.tfplan', '.terraform/', '.terraform.lock.hcl')
    $missing = @()
    
    foreach ($pattern in $patterns) {
        if ($content -notmatch [regex]::Escape($pattern)) {
            $missing += $pattern
        }
    }
    
    if ($missing.Count -gt 0) {
        $warnings += "gitignore missing patterns: $($missing -join ', ')"
    }
    
    return $true
}

function Test-TrackedFiles {
    $checks++
    
    # Check for files that shouldn't be tracked
    $badPatterns = @('\.tfstate', '\.tfplan', '\.terraform/')
    
    foreach ($pattern in $badPatterns) {
        $tracked = git ls-files | Select-String -Pattern $pattern
        if ($tracked) {
            $issues += "Tracked files matching '$pattern': $($tracked -join ', ')"
        }
    }
    
    return $true
}

function Test-PowerShellSyntax {
    param($ScriptPath)
    
    $checks++
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $ScriptPath -Raw), 
            [ref]$null
        )
        return $true
    } catch {
        $issues += "Syntax error in '$($ScriptPath)': $_"
        return $false
    }
}

# ============================================================================
# Run Checks
# ============================================================================

Write-Info "Running repository health checks..."
Write-Host ""

# Check 1: Scenario structure
Write-ColorOutput "Checking scenario structure..." -ForegroundColor Cyan
$scenarioDirs = Get-ChildItem -Path $PSScriptRoot -Directory | Where-Object {
    $_.Name -match '^\d{2}-'
}

foreach ($dir in $scenarioDirs) {
    if (Test-ScenarioStructure -ScenarioDir $dir) {
        Write-Success "  $($dir.Name) - OK"
    } else {
        Write-ErrorMsg "  $($dir.Name) - ISSUES FOUND"
    }
}

# Check 2: Git ignore
Write-Host ""
Write-ColorOutput "Checking .gitignore..." -ForegroundColor Cyan
if (Test-GitIgnore) {
    Write-Success "  .gitignore - OK"
}

# Check 3: Tracked files
Write-Host ""
Write-ColorOutput "Checking for improperly tracked files..." -ForegroundColor Cyan
if (Test-TrackedFiles) {
    Write-Success "  No problematic tracked files found"
}

# Check 4: PowerShell syntax
Write-Host ""
Write-ColorOutput "Checking PowerShell script syntax..." -ForegroundColor Cyan
$psScripts = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1"

foreach ($script in $psScripts) {
    if (Test-PowerShellSyntax -ScriptPath $script.FullName) {
        Write-Success "  $($script.Name) - OK"
    } else {
        Write-ErrorMsg "  $($script.Name) - SYNTAX ERROR"
    }
}

# Check 5: Required files
Write-Host ""
Write-ColorOutput "Checking required repository files..." -ForegroundColor Cyan
$requiredFiles = @('README.md', 'LICENSE', 'CONTRIBUTING.md', '.editorconfig', 'common-functions.ps1')

foreach ($file in $requiredFiles) {
    $checks++
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Write-Success "  $file - OK"
    } else {
        $issues += "Missing required file: $file"
        Write-ErrorMsg "  $file - MISSING"
    }
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Header "Summary"

Write-Info "Total checks performed: $checks"
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Success "All checks passed! Repository is healthy."
} else {
    if ($warnings.Count -gt 0) {
        Write-Warning2 "Warnings found: $($warnings.Count)"
        foreach ($warning in $warnings) {
            Write-ColorOutput "  ⚠️  $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    if ($issues.Count -gt 0) {
        Write-ErrorMsg "Issues found: $($issues.Count)"
        foreach ($issue in $issues) {
            Write-ColorOutput "  ❌ $issue" -ForegroundColor Red
        }
        Write-Host ""
        exit 1
    }
}

Write-Host ""
Write-Info "Health check complete!"
exit 0
