<#
.SYNOPSIS
  Runs a sequence of live response commands on a device.

.DESCRIPTION
  Runs a sequence of live response commands on a device.

.NOTES
  Author: Jan-Henrik Damaschke

.LINK
  https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/run-live-response?view=o365-worldwide

.PARAMETER id
  Specifies the id of the target MDE machine.

.PARAMETER comment
  Comment to associate with the action.

.PARAMETER commands
  Array of commands to run. Allowed values are "PutFile", "RunScript", "GetFile". See the reference link for more details on the body.

.EXAMPLE
  Invoke-MdeMachineLiveResponse -id "MACHINE_ID" -comment "Your comment" -commands @(@{type = "RunScript"; params = @(@{key = "scriptName"; value = "scriptFile.ps1"}; @{key = "Args"; value = "argument1"})})
#>

function Invoke-AzureRequest {
  [CmdletBinding()]
  param (
    [string]
    $uri,
    [Parameter(Mandatory = $false)]
    [hashtable]
    $headers = $null,
    [Parameter(Mandatory = $false)]
    [object]
    $body = $null
  )
  $reply = Invoke-RetryRequest -Method Get -Uri $uri -headers $headers -body $body
  $reply.value
  while (-not [String]::IsNullOrEmpty($reply.'@odata.nextLink') -or -not [String]::IsNullOrEmpty($reply.nextLink)) {
    Write-Verbose "Found next link: $($reply.'@odata.nextLink' ? $reply.'@odata.nextLink' : $reply.nextLink)"
    $reply = Invoke-RetryRequest -Method Get -Uri $($reply.'@odata.nextLink' ? $reply.'@odata.nextLink' : $reply.nextLink) -headers $headers -body $body
    foreach ($value in $reply.value) {
      $value
    }
  }
}
