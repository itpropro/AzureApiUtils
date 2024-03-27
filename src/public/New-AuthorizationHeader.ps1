<#
.SYNOPSIS
  Updates properties of existing Machine.

.DESCRIPTION
  Updates properties of existing Machine.

.NOTES
  Author: Jan-Henrik Damaschke

.LINK
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/update-machine-method?view=o365-worldwide

.EXAMPLE
  Update-MdeMachine -id '123' -tags @('tag-1', 'tag-2')

.EXAMPLE
  Update-MdeMachine -id '123' -priority 'High'

.ROLE
  @(@{permission = 'Machine.ReadWrite.All'; permissionType = 'Application'}, @{permission = 'Machine.ReadWrite'; permissionType = 'Delegated'})
#>
function New-AuthorizationHeader {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ParameterSetName = 'Bearer', Position = 0)]
    [string]
    $token,
    [Parameter(Mandatory, ParameterSetName = 'Basic')]
    [string]
    $username,
    [Parameter(Mandatory, ParameterSetName = 'Basic')]
    [securestring]
    $password,
    [Parameter(ParameterSetName = 'Basic')]
    [Parameter(ParameterSetName = 'Bearer')]
    [switch]
    $asJson
  )
  $header = @{Authorization = '' }
  if ($token) {
    $header.Authorization = "Bearer $token"
  }
  else {
    $basicAuth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${username}:$(ConvertFrom-SecureStrin -AsPlainText $password)"))
    $header.Authorization = "Basic $basicAuth"
  }
  $asJson ? (ConvertTo-Json -InputObject $header): $header
}
