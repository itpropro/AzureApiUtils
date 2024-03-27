BeforeAll {
  Remove-Module PSMDE -Force -ErrorAction SilentlyContinue
  Import-Module (Split-Path $PSCommandPath).replace('tests', 'src').Replace('public', 'PSMDE.psd1')
}

Describe "Enable-MdeMachineIsolation" {

  It 'Should have the PSMDE module loaded' {
    $module = Get-Module PSMDE
    $module | Should -Not -BeNullOrEmpty
  }

  It 'Should have access to internal functions' {
    InModuleScope PSMDE {
      $iar = Get-Command Invoke-AzureRequest
      $iar | Should -Not -BeNullOrEmpty
    }
  }

  It 'Should correctly create the request uri' {
    InModuleScope PSMDE {
      Mock Invoke-RetryRequest { return $uri }
      Mock Test-MdePermissions { return $true }
      $id = '12345'
      $comment = 'Comment'
      Enable-MdeMachineIsolation -id $id -comment $comment | Should -Be "https://api.securitycenter.microsoft.com/api/machines/$id/isolate"
    }
  }
}

"https://api.azrbac.mspim.azure.com/api/v2/privilegedAccess/aadroles/roleAssignments?`$expand=linkedEligibleRoleAssignment,subject,scopedResource,roleDefinition(`$expand=resource)&`$count=true&`$filter=(roleDefinition/resource/id eq '4f56a666-9f0c-4800-ba94-0cb1a7d20aee')+and+(roleDefinition/id eq 'f2ef992c-3afb-46b9-b7cf-a126ee74c451')+and+(assignmentState eq 'Eligible')&`$orderby=roleDefinition/displayName&`$skip=0&`$top=10"

$body = @{
  '$expand' = 'linkedEligibleRoleAssignment,subject,scopedResource,roleDefinition($expand=resource)'
  '$count' = $true
  '$filter' = "(roleDefinition/resource/id eq '4f56a666-9f0c-4800-ba94-0cb1a7d20aee') and (roleDefinition/id eq 'f2ef992c-3afb-46b9-b7cf-a126ee74c451') and (assignmentState eq 'Eligible')"
  '$orderby' = 'roleDefinition/displayName'
  '$skip' = 0
  '$top' = 10
}


$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0"
Invoke-WebRequest -UseBasicParsing -Uri "https://api.azrbac.mspim.azure.com/api/v2/privilegedAccess/aadroles/roleAssignmentRequests?`$expand=subject,scopedResource,roleDefinition(`$expand=resource)&`$filter=(status/subStatus+eq+%27Accepted%27+or+status/subStatus+eq+%27PendingEvaluation%27+or+status/subStatus+eq+%27Granted%27+or+status/subStatus+eq+%27PendingProvisioning%27+or+status/subStatus+eq+%27PendingApprovalProvisioning%27+or+status/subStatus+eq+%27PendingApproval%27+or+status/subStatus+eq+%27PendingAdminDecision%27+or+status/subStatus+eq+%27PendingScheduleCreation%27+or+status/subStatus+eq+%27ScheduleCreated%27)+and+(resourceId+eq+%274f56a666-9f0c-4800-ba94-0cb1a7d20aee%27)+and+(roleDefinitionId+eq+%27f2ef992c-3afb-46b9-b7cf-a126ee74c451%27)" `
-WebSession $session `
-Headers @{
"x-ms-client-session-id"="87a5eef4bc014e6aad65d483f4d20df5"
  "Accept-Language"="en"
  "Authorization"="Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSIsImtpZCI6IlhSdmtvOFA3QTNVYVdTblU3Yk05blQwTWpoQSJ9.eyJhdWQiOiIwMWZjMzNhNy03OGJhLTRkMmYtYTRiNy03NjhlMzM2ZTg5MGUiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC80ZjU2YTY2Ni05ZjBjLTQ4MDAtYmE5NC0wY2IxYTdkMjBhZWUvIiwiaWF0IjoxNzExNDk5Mjg5LCJuYmYiOjE3MTE0OTkyODksImV4cCI6MTcxMTUwNDgzOCwiYWNyIjoiMSIsImFpbyI6IkFYUUFpLzhXQUFBQWZ4bE9pVERlMGFiUE11MGNPdjZZaFkzUEUvak51K2RoZmI5MStJajd2ZGQ5aXp1T21Oa2pCcWM1N1BHU0lzQytIditQUXJRelplMkJXeklCZjV6Yjd3MzFXK2FNbDlJRzRWVU1taXgxbStlbGJzZ0tIYmxaaDNjTmV3eTBkSjNxL0dFRVpobklMT0xmaTBDRSsyZFBrZz09IiwiYW1yIjpbInB3ZCIsIm1mYSJdLCJhcHBpZCI6IjUwYWFhMzg5LTVhMzMtNGYxYS05MWQ3LTJjNDVlY2Q4ZGFjOCIsImFwcGlkYWNyIjoiMCIsImZhbWlseV9uYW1lIjoiRGFtYXNjaGtlIiwiZ2l2ZW5fbmFtZSI6Ikphbi1IZW5yaWsiLCJncm91cHMiOlsiNjZmMGNhYzMtOGE4YS00M2EzLTk2MDYtNDE1YzQyMzYzNTJlIiwiNzhjZmNhMDAtYjhkOC00ZDU3LWIxZWQtNjU0OGRlZDM3YjY3IiwiY2JjZWI2NGQtNGI4NS00ZWI2LWJhODItNTU5NDY4ZWFkZDczIiwiOGRkMDU3ZGUtYjEzYi00NTAyLWI5N2YtZTlmYWI2YmYyYjc1Il0sImlwYWRkciI6IjgwLjE4Ny4xMjYuNCIsIm5hbWUiOiJDMCBKYW4tSGVucmlrIERhbWFzY2hrZSIsIm9pZCI6IjUwNzJhZjY5LTc0MjUtNDIyMi05MGUxLWNmODM0MTNiMzkxZCIsInB1aWQiOiIxMDAzMjAwMUQ1MDI2ODc1IiwicmgiOiIwLkFVY0FacVpXVHd5ZkFFaTZsQXl4cDlJSzdxY3pfQUc2ZUM5TnBMZDJqak51aVE0TkFYOC4iLCJzY3AiOiJ1c2VyX2ltcGVyc29uYXRpb24iLCJzdWIiOiI1Q3VubnVtbGlOdUdXQ0xYOW9feHpVZ3g4NFZoei1GaldtdVN5UUNpRU8wIiwidGlkIjoiNGY1NmE2NjYtOWYwYy00ODAwLWJhOTQtMGNiMWE3ZDIwYWVlIiwidW5pcXVlX25hbWUiOiJjMF9kYW1hc2Noa2VAb3R0b2JvY2tnbG9iYWwub25taWNyb3NvZnQuY29tIiwidXBuIjoiYzBfZGFtYXNjaGtlQG90dG9ib2NrZ2xvYmFsLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6IllWWXdwcFZCZzBhaWs3U3VhUGtGQUEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfdGRiciI6IkVVIn0.etXZM90NLJIY0E6imBa9aejwscLMwACkGzXBuGlUNoEnvKuHUp9DlL2Hc2YcUaj2GdNCZCn_JrrZqiRGvNMxpg0SMypNtc4o7KZGeStIWaDigPtdgBxSKvlIgrpY95yOz926BkgfiKYrgo0RuSvFH1yGCbQymEqI94ib6sdlI3iuY1dK9Hd87cg6gWlQv4V4eOAIksE3k2yi1_Uv7syaJ65tkV8kz90vacmdZIlazhHq5xvl0ttPJ-q2m-5cKc_qCmTLn1pavIf34vgJN3WfDxUEVvM5xL93xC7eHrHCKm8pb5dfSfHl9vNAiHojIZePo0hvpEP-RagGgcXm2hm9cQ"
  "x-ms-effective-locale"="en.en-us"
  "Accept"="application/json, text/javascript, */*; q=0.01"
  "Referer"=""
  "x-ms-client-request-id"="4f463154-d15f-449f-8334-24de0ab89004"
}