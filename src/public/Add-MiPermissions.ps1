<#
.SYNOPSIS
  Adds permissions to a specific managed identity

.DESCRIPTION
  Adds permissions to a specific managed identity

.NOTES
  Author: Jan-Henrik Damaschke

.EXAMPLE
  Add-MsiPermissions -msiObjectId '123' -graphPermissions @('User.Read.All')

.ROLE
  @(@{permission = 'Machine.ReadWrite.All'; permissionType = 'Application'}, @{permission = 'Machine.ReadWrite'; permissionType = 'Delegated'})
#>

function Add-MsiPermissions {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String]
    $tenantId,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
    [string]
    $msiObjectId,
    [Parameter()]
    [String]
    $referenceAppId = "00000003-0000-0000-c000-000000000000", # Well known Graph API ID
    [parameter(Mandatory)]
    [array]
    $graphPermissions
  )
  
  Begin {
    Connect-AzureAD -TenantId $tenantId
  }
  Process {
    $msi = Get-AzureADServicePrincipal -Filter "objectId eq '$msiObjectId'"
    # TODO: Implement possibility to provide name instead of ID: Get-AzureADServicePrincipal -Filter "displayName eq 'Office 365 Exchange Online'"
    $referenceAppRegistration = Get-AzureADServicePrincipal -Filter "appId eq '$referenceAppId'"
    $appRoles = $referenceAppRegistration.AppRoles | Where-Object { $graphPermissions -contains $_.Value -and $_.AllowedMemberTypes -contains "Application" }
    foreach ($appRole in $appRoles) {
      New-AzureAdServiceAppRoleAssignment -ObjectId $msi.ObjectId -PrincipalId $msi.ObjectId -ResourceId $referenceAppRegistration.ObjectId -Id $appRole.Id
    }
  }
  End {}
}
