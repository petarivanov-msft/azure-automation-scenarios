<#
.SYNOPSIS
    Demonstrates parallel processing in PowerShell 7.4
.DESCRIPTION
    Compares sequential vs parallel processing performance
#>

Write-Output "=== Parallel Processing Demo ==="

# Connect to Azure
Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity | Out-Null
Write-Output "Connected successfully"
Write-Output ""

# Get resource groups
$resourceGroups = Get-AzResourceGroup | Select-Object -First 5
Write-Output "Processing $($resourceGroups.Count) resource groups..."
Write-Output ""

# Sequential Processing
Write-Output "=== Sequential Processing ==="
$seqStart = Get-Date
$seqResults = $resourceGroups | ForEach-Object {
    Get-AzResource -ResourceGroupName $_.ResourceGroupName -ErrorAction SilentlyContinue
}
$seqDuration = (Get-Date) - $seqStart
Write-Output "Duration: $($seqDuration.TotalSeconds) seconds"
Write-Output "Resources found: $($seqResults.Count)"
Write-Output ""

# Parallel Processing (PowerShell 7.4 feature)
Write-Output "=== Parallel Processing ==="
$parStart = Get-Date
$parResults = $resourceGroups | ForEach-Object -Parallel {
    Get-AzResource -ResourceGroupName $_.ResourceGroupName -ErrorAction SilentlyContinue
} -ThrottleLimit 5
$parDuration = (Get-Date) - $parStart
Write-Output "Duration: $($parDuration.TotalSeconds) seconds"
Write-Output "Resources found: $($parResults.Count)"
Write-Output ""

# Performance Comparison
$improvement = [math]::Round((1 - ($parDuration.TotalSeconds / $seqDuration.TotalSeconds)) * 100, 2)
Write-Output "=== Performance Summary ==="
Write-Output "Sequential: $($seqDuration.TotalSeconds)s"
Write-Output "Parallel: $($parDuration.TotalSeconds)s"
Write-Output "Improvement: $improvement%"
