BeforeAll {
  Remove-Module PSMDE -Force -ErrorAction SilentlyContinue
  Import-Module (Split-Path $PSCommandPath).replace('tests', 'src').Replace('public', 'PSMDE.psd1')
}

Describe "Remove-MdeMachineTag" {

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
      Mock Invoke-RetryRequest { return @{uri = $uri; body = $body } }
      Mock Test-MdePermissions { return $true }
      $id = '12345'
      $tag = 'monitored'
      $body = ConvertTo-Json -Depth 5 -InputObject @{ Value = $tag; Action = 'Remove' }
      $result = Remove-MdeMachineTag -id $id -tag $tag
      $result.uri | Should -Be "https://api.securitycenter.microsoft.com/api/machines/$id/tags"
      $result.body | Should -Be $body
    }
  }
}