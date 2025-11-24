<#
.SYNOPSIS
    Demonstrates PowerShell 7.4 language features
.DESCRIPTION
    Showcases modern PowerShell 7.4 syntax including ternary operators, null coalescing, and more
#>

Write-Output "=== PowerShell 7.4 Features Demo ==="
Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Output ""

# Connect to Azure
Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity | Out-Null
Write-Output "Connected to: $((Get-AzContext).Subscription.Name)"
Write-Output ""

# Ternary Operator
Write-Output "=== Ternary Operator ==="
$isProduction = $false
$environment = $isProduction ? "Production" : "Development"
Write-Output "Environment: $environment"
Write-Output ""

# Null Coalescing
Write-Output "=== Null Coalescing Operator ==="
$configValue = $null
$finalValue = $configValue ?? "default-value"
Write-Output "Final value: $finalValue"
Write-Output ""

# Pipeline Chain Operators
Write-Output "=== Pipeline Chain Operators ==="
$result = Get-AzResourceGroup | Select-Object -First 1
if ($result) {
    Write-Output "Successfully got resource group: $($result.ResourceGroupName)"
} else {
    Write-Output "No resource groups found"
}
Write-Output ""

# Modern String Interpolation
Write-Output "=== Modern Features ==="
$rgs = @(Get-AzResourceGroup)
Write-Output "Total Resource Groups: $($rgs.Count)"
Write-Output ""

Write-Output "Demo completed successfully!"
