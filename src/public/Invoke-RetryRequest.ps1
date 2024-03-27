<#
.SYNOPSIS
  Creates a service principal (app registration) for Defender for Endpoint.

.DESCRIPTION
  Creates a service principal (app registration) for Defender for Endpoint with a given set of permissions to interact with MDE.

.NOTES
  Author: Jan-Henrik Damaschke

.PARAMETER name
  Optional. Service principal name, defaults to 'PSMDE'.

.PARAMETER permissions
  Optional. Service principal permissions, defaults to 'read'. Possible values are 'read', 'readwrite'. Assigns either all 'Read' or all 'ReadWrite' permissions to the new service principal.

.PARAMETER delegated
  Optional. If defined, the service principal will be created with delegated, not with application permissions.

.PARAMETER initialize
  Optional. If defined, a secret will be generated and the service principal details will be handed over to Set-MdeAuthorizationInfo.

.PARAMETER dontOpenGrantUrl
  Optional. If defined, it will not open a browser after the service principal was created to grant permissions.

.LINK
  https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/exposed-apis-create-app-webapp?view=o365-worldwide

.EXAMPLE
  New-MdeServicePrincipal -name 'PSMDE-SP' -permissions 'read' -delegated

.EXAMPLE
  New-MdeServicePrincipal -permissions 'readwrite' -initialize

.EXAMPLE
  New-MdeServicePrincipal -dontOpenGrantUrl
#>

function Invoke-RetryRequest {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $method = 'get',
    [Parameter(Mandatory,
      ValueFromPipelineByPropertyName)]
    [string]
    $uri,
    [Parameter(Mandatory = $false)]
    [hashtable]
    $headers = $null,
    [Parameter(Mandatory = $false)]
    [object]
    $body = $null,
    [Parameter(Mandatory = $false)]
    [int]
    $maxRetrySeconds = 2000
  )
  Write-Verbose "Invoking retry request with uri: $uri"
  $sleepDuration = 0
  $retry = $false
  do {
    try {
      $retry = $false
      Invoke-RestMethod -Method $method -Headers $headers -ContentType 'application/json' -Uri $uri -Body $body -ErrorAction Stop -Verbose:$false
    }
    catch {
      if ($_.Exception.Response.StatusCode.value__ -ne 429) { $retry = $false; $_; break }
      $sleepDuration = $sleepDuration -eq 0 ? 4 : $sleepDuration * 2
      $retry = $true
      Write-Verbose "API returned 429, retrying in $sleepDuration seconds"
      Start-Sleep -Seconds $sleepDuration
    }
  } until (
    -not $retry -or ($sleepDuration -ge $maxRetrySeconds)
  )
}
