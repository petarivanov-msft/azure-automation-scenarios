<#
.SYNOPSIS
    Retrieves group information from Microsoft Graph API
.DESCRIPTION
    Uses managed identity to connect to Microsoft Graph and retrieve groups
    Demonstrates Group.Read.All permission usage
#>

param(
    [int]$TopCount = 10,
    [string]$GroupType = "All"  # All, Security, Microsoft365
)

Write-Output "Starting Get-GroupsReport runbook..."
Write-Output "Parameters: TopCount=$TopCount, GroupType=$GroupType"

try {
    # Connect using managed identity
    Connect-MgGraph -Identity -NoWelcome
    Write-Output "Successfully connected to Microsoft Graph"
    
    Write-Output "`nRetrieving groups..."
    
    # Get groups from Microsoft Graph
    $groups = Get-MgGroup -Top $TopCount -Property DisplayName,Description,GroupTypes,CreatedDateTime,SecurityEnabled,MailEnabled -Sort DisplayName
    
    # Filter by group type if specified
    if ($GroupType -eq "Security") {
        $groups = $groups | Where-Object { $_.SecurityEnabled -eq $true -and $_.MailEnabled -eq $false }
    } elseif ($GroupType -eq "Microsoft365") {
        $groups = $groups | Where-Object { $_.GroupTypes -contains "Unified" }
    }
    
    Write-Output "`nFound $($groups.Count) groups:"
    Write-Output "=" * 80
    
    foreach ($group in $groups) {
        Write-Output "`nGroup Name: $($group.DisplayName)"
        Write-Output "Description: $($group.Description)"
        
        if ($group.GroupTypes -contains "Unified") {
            Write-Output "Type: Microsoft 365 Group"
        } elseif ($group.SecurityEnabled) {
            Write-Output "Type: Security Group"
        } else {
            Write-Output "Type: Distribution Group"
        }
        
        Write-Output "Security Enabled: $($group.SecurityEnabled)"
        Write-Output "Mail Enabled: $($group.MailEnabled)"
        Write-Output "Created: $($group.CreatedDateTime)"
        Write-Output "-" * 80
    }
    
    Write-Output "`nTotal groups retrieved: $($groups.Count)"
    Write-Output "Runbook completed successfully!"
    
} catch {
    Write-Error "Error occurred: $_"
    Write-Error $_.Exception.Message
    throw
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
