<#
.SYNOPSIS
    Stops VMs based on PowerSchedule tag (excludes AlwaysOn)
.DESCRIPTION
    Connects with managed identity and stops VMs with matching PowerSchedule tag
#>

param(
    [string]$Schedule = "BusinessHours",
    [bool]$Force = $false
)

Write-Output "=== Stop VMs by Tag Runbook ==="
Write-Output "Schedule filter: $Schedule"
Write-Output "Force: $Force"
Write-Output "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    # Connect using managed identity
    Write-Output "`nConnecting to Azure..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected to: $((Get-AzContext).Subscription.Name)"
    
    # Get all VMs with matching PowerSchedule tag (exclude AlwaysOn)
    Write-Output "`nGetting VMs with PowerSchedule: $Schedule..."
    $vms = Get-AzVM | Where-Object {
        $_.Tags.PowerSchedule -eq $Schedule -and $_.Tags.PowerSchedule -ne "AlwaysOn"
    }
    
    if ($vms.Count -eq 0) {
        Write-Output "No VMs found with PowerSchedule: $Schedule"
        return
    }
    
    Write-Output "Found $($vms.Count) VM(s) to stop`n"
    
    $stoppedCount = 0
    $alreadyStoppedCount = 0
    $failedCount = 0
    
    foreach ($vm in $vms) {
        Write-Output "VM: $($vm.Name)"
        Write-Output "  Resource Group: $($vm.ResourceGroupName)"
        Write-Output "  PowerSchedule: $($vm.Tags.PowerSchedule)"
        
        # Get current state
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
        Write-Output "  Current State: $powerState"
        
        if ($powerState -eq "deallocated" -or $powerState -eq "stopped") {
            Write-Output "  Action: Already stopped"
            $alreadyStoppedCount++
        }
        else {
            Write-Output "  Action: Stopping VM..."
            try {
                if ($Force) {
                    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait | Out-Null
                } else {
                    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait | Out-Null
                }
                Write-Output "  Result: Stop command sent successfully"
                $stoppedCount++
            }
            catch {
                Write-Error "  Result: Failed to stop - $_"
                $failedCount++
            }
        }
        Write-Output ""
    }
    
    # Summary
    Write-Output "=== Summary ==="
    Write-Output "Total VMs processed: $($vms.Count)"
    Write-Output "Stopped: $stoppedCount"
    Write-Output "Already stopped: $alreadyStoppedCount"
    Write-Output "Failed: $failedCount"
    Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
}
catch {
    Write-Error "Runbook failed: $_"
    Write-Error $_.Exception.Message
    throw
}
