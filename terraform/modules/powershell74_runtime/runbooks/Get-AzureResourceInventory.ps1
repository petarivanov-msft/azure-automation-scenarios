<#
.SYNOPSIS
    Azure Resource Inventory using modern PowerShell
.DESCRIPTION
    Generates comprehensive inventory report using PowerShell 7.4 features
#>

param(
    [int]$TopResourceGroups = 10
)

Write-Output "=== Azure Resource Inventory ==="
Write-Output "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Connect to Azure
Connect-AzAccount -Identity | Out-Null
$context = Get-AzContext
Write-Output "Subscription: $($context.Subscription.Name)"
Write-Output ""

# Get all resource groups
$resourceGroups = Get-AzResourceGroup | Select-Object -First $TopResourceGroups
Write-Output "Analyzing top $($resourceGroups.Count) resource groups..."
Write-Output ""

# Process resource groups in parallel
$inventory = $resourceGroups | ForEach-Object -Parallel {
    $rg = $_
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
    
    [PSCustomObject]@{
        ResourceGroupName = $rg.ResourceGroupName
        Location = $rg.Location
        ResourceCount = $resources.Count
        ResourceTypes = ($resources | Group-Object ResourceType).Count
        Tags = $rg.Tags ?? @{}
    }
} -ThrottleLimit 10

# Display results
Write-Output "=== Resource Group Summary ==="
Write-Output "=" * 80
foreach ($item in $inventory) {
    Write-Output "`nResource Group: $($item.ResourceGroupName)"
    Write-Output "  Location: $($item.Location)"
    Write-Output "  Resources: $($item.ResourceCount)"
    Write-Output "  Resource Types: $($item.ResourceTypes)"
    Write-Output "  Tags: $(if ($item.Tags.Count) { $item.Tags.Keys -join ', ' } else { 'None' })"
    Write-Output "-" * 80
}

Write-Output "`nInventory completed successfully!"
