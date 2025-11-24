<#
.SYNOPSIS
    Reports power state of all VMs
.DESCRIPTION
    Generates a report showing current power state and tags for all VMs
#>

Write-Output "=== VM Power State Report ==="
Write-Output "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    # Connect using managed identity
    Write-Output "`nConnecting to Azure..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected to: $((Get-AzContext).Subscription.Name)"
    
    # Get all VMs
    Write-Output "`nRetrieving all VMs..."
    $vms = Get-AzVM
    
    if ($vms.Count -eq 0) {
        Write-Output "No VMs found in subscription"
        return
    }
    
    Write-Output "Found $($vms.Count) VM(s)`n"
    Write-Output "=" * 80
    
    foreach ($vm in $vms) {
        # Get VM status
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
        
        Write-Output "`nVM Name: $($vm.Name)"
        Write-Output "  Resource Group: $($vm.ResourceGroupName)"
        Write-Output "  Location: $($vm.Location)"
        Write-Output "  Size: $($vm.HardwareProfile.VmSize)"
        Write-Output "  Power State: $powerState"
        Write-Output "  PowerSchedule Tag: $($vm.Tags.PowerSchedule ?? 'Not Set')"
        Write-Output "  Environment Tag: $($vm.Tags.Environment ?? 'Not Set')"
        Write-Output "-" * 80
    }
    
    # Summary by power state
    Write-Output "`n=== Summary by Power State ==="
    $vmStatuses = $vms | ForEach-Object {
        $status = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status
        ($status.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
    }
    
    $vmStatuses | Group-Object | ForEach-Object {
        Write-Output "$($_.Name): $($_.Count) VM(s)"
    }
    
    # Summary by PowerSchedule
    Write-Output "`n=== Summary by PowerSchedule ==="
    $vms | Group-Object { $_.Tags.PowerSchedule ?? 'Not Set' } | ForEach-Object {
        Write-Output "$($_.Name): $($_.Count) VM(s)"
    }
    
    Write-Output "`nReport completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
catch {
    Write-Error "Report failed: $_"
    Write-Error $_.Exception.Message
    throw
}
