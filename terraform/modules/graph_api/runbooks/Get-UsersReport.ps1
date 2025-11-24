<#
.SYNOPSIS
    Retrieves user information from Microsoft Graph API
.DESCRIPTION
    Uses managed identity to connect to Microsoft Graph and retrieve users
    Demonstrates User.Read.All permission usage
#>

param(
    [int]$TopCount = 10
)

Write-Output "Starting Get-UsersReport runbook..."
Write-Output "Connecting to Microsoft Graph using Managed Identity..."

try {
    # Connect using managed identity
    Connect-MgGraph -Identity -NoWelcome
    
    Write-Output "Successfully connected to Microsoft Graph"
    Write-Output "Current context: $(Get-MgContext | Select-Object -ExpandProperty Account)"
    
    Write-Output "`nRetrieving top $TopCount users..."
    
    # Get users from Microsoft Graph
    $users = Get-MgUser -Top $TopCount -Property DisplayName,UserPrincipalName,Mail,AccountEnabled,CreatedDateTime,UserType -Sort DisplayName
    
    Write-Output "`nFound $($users.Count) users:"
    Write-Output "=" * 80
    
    foreach ($user in $users) {
        Write-Output "`nDisplay Name: $($user.DisplayName)"
        Write-Output "UPN: $($user.UserPrincipalName)"
        Write-Output "Email: $($user.Mail)"
        Write-Output "Account Enabled: $($user.AccountEnabled)"
        Write-Output "User Type: $($user.UserType)"
        Write-Output "Created: $($user.CreatedDateTime)"
        Write-Output "-" * 80
    }
    
    Write-Output "`nTotal users retrieved: $($users.Count)"
    Write-Output "Runbook completed successfully!"
    
} catch {
    Write-Error "Error occurred: $_"
    Write-Error $_.Exception.Message
    throw
} finally {
    # Disconnect from Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
