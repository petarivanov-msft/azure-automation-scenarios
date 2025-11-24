<#
.SYNOPSIS
    Retrieves application information from Microsoft Graph API
.DESCRIPTION
    Uses managed identity to connect to Microsoft Graph and retrieve applications
    Demonstrates Application.Read.All permission usage
#>

param(
    [int]$TopCount = 10
)

Write-Output "Starting Get-ApplicationsReport runbook..."

try {
    # Connect using managed identity
    Connect-MgGraph -Identity -NoWelcome
    Write-Output "Successfully connected to Microsoft Graph"
    
    Write-Output "`nRetrieving top $TopCount applications..."
    
    # Get applications from Microsoft Graph
    $apps = Get-MgApplication -Top $TopCount -Property DisplayName,AppId,CreatedDateTime,SignInAudience -Sort DisplayName
    
    Write-Output "`nFound $($apps.Count) applications:"
    Write-Output "=" * 80
    
    foreach ($app in $apps) {
        Write-Output "`nApplication Name: $($app.DisplayName)"
        Write-Output "Application (Client) ID: $($app.AppId)"
        Write-Output "Sign-In Audience: $($app.SignInAudience)"
        Write-Output "Created: $($app.CreatedDateTime)"
        Write-Output "-" * 80
    }
    
    Write-Output "`nTotal applications retrieved: $($apps.Count)"
    Write-Output "Runbook completed successfully!"
    
} catch {
    Write-Error "Error occurred: $_"
    Write-Error $_.Exception.Message
    throw
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
