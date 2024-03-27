BeforeAll {
  Remove-Module AzureApiUtils -Force -ErrorAction SilentlyContinue
  Import-Module (Split-Path $PSCommandPath).replace('tests', 'src').Replace('public', 'AzureApiUtils.psd1')
}

Describe "Add-AppPermission" {

  It 'Should have the AzureApiUtils module loaded' {
    $module = Get-Module AzureApiUtils
    $module | Should -Not -BeNullOrEmpty
  }
}