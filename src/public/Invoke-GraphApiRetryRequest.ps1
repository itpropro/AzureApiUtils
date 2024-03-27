<#
.SYNOPSIS
  Set the authorization information that is used to get a valid MDE token.

.DESCRIPTION
  Set the authorization information that is used to get a valid MDE token. You can use a service principal (app registration) or directly provide a token.

.NOTES
  Author: Jan-Henrik Damaschke

.PARAMETER tenantId
  Mandatory. Service principal tenant id.

.PARAMETER appId
  Mandatory. Service principal app id.

.PARAMETER appSecret
  Mandatory. Service principal secret.

.PARAMETER noTokenRefresh
  Optional. If this switch is provided, no token refresh is performed.

.PARAMETER token
  Mandatory. You can provide the token directly with this parameter. If used, none of the other parameters can be used.

.PARAMETER configurationFile
  You can provide a JSON parameter file containing the values "mdeAppId","mdeTenantId" and "mdeAppSecret".

.PARAMETER fromEnv
  If this switch is provided, the app registration credentials will be taken from the environment variables "MDE_APP_ID", "MDE_TENANT_ID", "MDE_APP_SECRET"

.LINK
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/exposed-apis-create-app-webapp?view=o365-worldwide

.EXAMPLE
  Set-MdeAuthorizationInfo -tenantId '00000000-0000-0000-0000-000000000000' -appId '00000000-0000-0000-0000-000000000000' -appSecret 'APP_SECRET'

.EXAMPLE
  Set-MdeAuthorizationInfo -fromEnv

.EXAMPLE
  Set-MdeAuthorizationInfo -configurationFile "./mdeConfig.json"
#>

function Invoke-GraphApiRetryRequest {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $method = 'get',
    [Parameter(Mandatory,
      ValueFromPipelineByPropertyName)]
    [string]
    $uri,
    [Parameter(ValueFromPipelineByPropertyName)]
    [object]
    $body
  )
  Write-Verbose "Invoking Graph API retry request with uri: $uri"
  $sleepDuration = 0
  $retry = $false
  do {
    try {
      $retry = $false
      if (@('put', 'patch', 'post') -contains $method.ToLower()) {
        Invoke-MgGraphRequest -Method $method -Uri $uri -Body $body -ErrorAction Stop
      }
      else {
        Invoke-MgGraphRequest -Method $method -Uri $uri -ErrorAction Stop
      }
    }
    catch {
      if ($_.Exception.Response.StatusCode.value__ -ne 429) { $retry = $false; $_; break }
      $sleepDuration = $sleepDuration -eq 0 ? 4 : $sleepDuration * 2
      $retry = $true
      Write-Verbose "API returned 429, retrying in $sleepDuration seconds"
      Start-Sleep -Seconds $sleepDuration
    }
  } until (
    -not $retry
  )
}
