<#
.SYNOPSIS
    Starts VMs based on PowerSchedule tag
.DESCRIPTION
    Connects with managed identity and starts VMs with matching PowerSchedule tag
#>

param(
    [string]$Schedule = "BusinessHours"
)

Write-Output "=== Start VMs by Tag Runbook ==="
Write-Output "Schedule filter: $Schedule"
Write-Output "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    # Connect using managed identity
    Write-Output "`nConnecting to Azure..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected to: $((Get-AzContext).Subscription.Name)"
    
    # Get all VMs with matching PowerSchedule tag
    Write-Output "`nGetting VMs with PowerSchedule: $Schedule..."
    $vms = Get-AzVM | Where-Object { $_.Tags.PowerSchedule -eq $Schedule }
    
    if ($vms.Count -eq 0) {
        Write-Output "No VMs found with PowerSchedule: $Schedule"
        return
    }
    
    Write-Output "Found $($vms.Count) VM(s) to start`n"
    
    $startedCount = 0
    $alreadyRunningCount = 0
    $failedCount = 0
    
    foreach ($vm in $vms) {
        Write-Output "VM: $($vm.Name)"
        Write-Output "  Resource Group: $($vm.ResourceGroupName)"
        Write-Output "  PowerSchedule: $($vm.Tags.PowerSchedule)"
        
        # Get current state
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
        Write-Output "  Current State: $powerState"
        
        if ($powerState -eq "running") {
            Write-Output "  Action: Already running"
            $alreadyRunningCount++
        }
        else {
            Write-Output "  Action: Starting VM..."
            try {
                Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait | Out-Null
                Write-Output "  Result: Start command sent successfully"
                $startedCount++
            }
            catch {
                Write-Error "  Result: Failed to start - $_"
                $failedCount++
            }
        }
        Write-Output ""
    }
    
    # Summary
    Write-Output "=== Summary ==="
    Write-Output "Total VMs processed: $($vms.Count)"
    Write-Output "Started: $startedCount"
    Write-Output "Already running: $alreadyRunningCount"
    Write-Output "Failed: $failedCount"
    Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
}
catch {
    Write-Error "Runbook failed: $_"
    Write-Error $_.Exception.Message
    throw
}
