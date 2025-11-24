<#
.SYNOPSIS
    Tests Hybrid Worker with managed identity authentication
.DESCRIPTION
    Connects to Azure using VM's managed identity and retrieves VM information
#>

Write-Output "=== Hybrid Worker Test with Managed Identity ==="
Write-Output "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "Computer Name: $env:COMPUTERNAME"
Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Output ""

try {
    # Connect using managed identity (VM's identity, not Automation Account's)
    Write-Output "Connecting to Azure using Hybrid Worker VM's managed identity..."
    Connect-AzAccount -Identity | Out-Null
    
    $context = Get-AzContext
    Write-Output "Successfully connected!"
    Write-Output "Subscription: $($context.Subscription.Name)"
    Write-Output "Account: $($context.Account.Id)"
    Write-Output ""
    
    # List all VMs in subscription
    Write-Output "=== Virtual Machines in Subscription ==="
    $vms = Get-AzVM
    Write-Output "Found $($vms.Count) VM(s):"
    Write-Output ""
    
    foreach ($vm in $vms | Select-Object -First 10) {
        Write-Output "VM: $($vm.Name)"
        Write-Output "  Resource Group: $($vm.ResourceGroupName)"
        Write-Output "  Location: $($vm.Location)"
        Write-Output "  Size: $($vm.HardwareProfile.VmSize)"
        Write-Output "  OS: $($vm.StorageProfile.OsDisk.OsType)"
        Write-Output ""
    }
    
    # Get details about the Hybrid Worker VM itself
    Write-Output "=== Hybrid Worker VM Details ==="
    $hwVM = Get-AzVM | Where-Object { $_.Name -like "*hybrid*" } | Select-Object -First 1
    
    if ($hwVM) {
        Write-Output "Hybrid Worker VM: $($hwVM.Name)"
        Write-Output "  Resource Group: $($hwVM.ResourceGroupName)"
        Write-Output "  Location: $($hwVM.Location)"
        Write-Output "  Size: $($hwVM.HardwareProfile.VmSize)"
        Write-Output "  Provisioning State: $($hwVM.ProvisioningState)"
        
        # Get VM status
        $vmStatus = Get-AzVM -ResourceGroupName $hwVM.ResourceGroupName -Name $hwVM.Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code -replace "PowerState/",""
        Write-Output "  Power State: $powerState"
        
        # Get extensions
        Write-Output "  Extensions:"
        foreach ($ext in $hwVM.Extensions) {
            Write-Output "    - $($ext.Name) ($($ext.Publisher)/$($ext.VirtualMachineExtensionType))"
        }
    } else {
        Write-Output "Could not find Hybrid Worker VM"
    }
    
    Write-Output ""
    Write-Output "=== Test Summary ==="
    Write-Output "Status: SUCCESS"
    Write-Output "Hybrid Worker is functioning correctly with managed identity!"
    Write-Output "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
} catch {
    Write-Error "Test failed: $_"
    Write-Error $_.Exception.Message
    Write-Output ""
    Write-Output "=== Test Summary ==="
    Write-Output "Status: FAILED"
    Write-Output "See error details above"
    throw
}
