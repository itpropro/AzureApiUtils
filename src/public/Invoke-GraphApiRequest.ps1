<#
.SYNOPSIS
  Offboard device from Defender for Endpoint.

.DESCRIPTION
  Offboard device from Defender for Endpoint.

.NOTES
  Author: Jan-Henrik Damaschke

.LINK
  https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/offboard-machine-api?view=o365-worldwide

.PARAMETER id
  Specifies the id of the target MDE machine.

.PARAMETER comment
  Comment to associate with the action.

.EXAMPLE
  Remove-MdeMachine -id "MACHINE_ID" -comment "Your comment"

.ROLE
  @(@{permission = 'Machine.Offboard'; permissionType = 'Application'}, @{permission = 'Machine.Offboard'; permissionType = 'Delegated'})
#>

function Invoke-GraphApiRequest {
  [CmdletBinding()]
  param (
    [string]
    $uri,
    [string]
    $method = 'get'
  )
  $reply = Invoke-GraphApiRetryRequest -Method $method -Uri $uri
  $reply.value
  while (-not [String]::IsNullOrEmpty($reply.'@odata.nextLink')) {
    Write-Verbose "Found next link: $($reply.'@odata.nextLink')"
    $reply = Invoke-GraphApiRetryRequest -Method $method -Uri $reply.'@odata.nextLink'
    foreach ($value in $reply.value) {
      $value
    }
  }
}