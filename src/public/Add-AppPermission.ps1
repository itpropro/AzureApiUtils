<#
.SYNOPSIS
  This function adds application permissions to an app in Entra ID.

.DESCRIPTION
  The Add-AppPermission function uses the Microsoft Graph API to add application permissions to an app in Entra ID. 
  It requires the Microsoft.Graph.Authentication module to authenticate to the Graph API.

.PARAMETER tenantId
  Optional. The ID of the tenant where the app resides.

.PARAMETER objectId
  Mandatory. The object ID of the app to which permissions will be added. This parameter is mandatory for the 'ObjectId' parameter set.

.PARAMETER appId
  Mandatory. The application ID of the app to which permissions will be added. This parameter is mandatory for the 'AppId' parameter set.

.PARAMETER referenceAppId
  Optional. The application ID of the reference app. This is used to fetch the app roles that will be assigned. 
  By default, it is set to the well-known Graph API ID.

.PARAMETER referenceAppName
  Optional. The display name of the reference app. This is used to fetch the app roles that will be assigned.

.PARAMETER appPermissions
  Mandatory. An array of permissions that will be added to the app. This parameter is mandatory.

.PARAMETER silent
  Optional. A switch parameter. If provided, the function will not output anything.

.EXAMPLE
  Add-AppPermission -tenantId "your-tenant-id" -appId "your-app-id" -appPermissions @("Permission1", "Permission2")

.EXAMPLE
  Add-AppPermission -appId 'your-app-id' -appPermissions @('User.Read.All')

.EXAMPLE
  Add-AppPermission -appId 'your-app-id' -appPermissions @('Exchange.ManageAsApp') -referenceAppName 'Office 365 Exchange Online'
#>

function Add-AppPermission {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String]
    $tenantId,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'ObjectId')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'referenceAppId')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'referenceAppName')]
    [string]
    $objectId,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'AppId')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'referenceAppId')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, ParameterSetName = 'referenceAppName')]
    [string]
    $appId,
    [Parameter(ParameterSetName = 'AppId')]
    [Parameter(ParameterSetName = 'ObjectId')]
    [Parameter(ParameterSetName = 'referenceAppId')]
    [String]
    $referenceAppId = "00000003-0000-0000-c000-000000000000", # Well known Graph API ID
    [Parameter(ParameterSetName = 'AppId')]
    [Parameter(ParameterSetName = 'ObjectId')]
    [Parameter(ParameterSetName = 'referenceAppName')]
    [String]
    $referenceAppName,
    [Parameter(Mandatory)]
    [array]
    $appPermissions,
    [Parameter()]
    [switch]
    $silent
  )
  
  Begin {
    try {
      Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    }
    catch {
      Throw "Microsoft.Graph.Authentication module cannot be loaded"
    }
    if (-not (Get-MgContext)) { 
      Write-Verbose "No MgGraph context found, executing Connect-MgGraph"
      Connect-MgGraph
    }
  }
  Process {
    $baseUri = $appId ? "/beta/servicePrincipals(appId='$appId')" : "/beta/servicePrincipals/$objectId"
    $app = Invoke-GraphApiRequest -Uri $baseUri
    $referenceAppRegistration = $referenceAppName ? (Invoke-GraphApiRequest -Uri "/beta/servicePrincipals?`$filter=displayName eq '$referenceAppName'") : (Invoke-GraphApiRequest -Uri "/beta/servicePrincipals(appId='$referenceAppId')")
    $appRoles = $referenceAppRegistration.appRoles | Where-Object { $appPermissions -contains $_.Value -and $_.allowedMemberTypes -eq 'Application' }
    foreach ($appRole in $appRoles) {
      $params = @{
        principalId = $app.id
        resourceId = $referenceAppRegistration.id
        appRoleId = $appRole.id
      }
      try {
        $silent ? ($null = Invoke-GraphApiRequest -uri "$baseUri/appRoleAssignments" -method post -body $params) : (Invoke-GraphApiRequest -uri "$baseUri/appRoleAssignments" -method post -body $params)
      }
      catch {
        if ($_.ErrorDetails.Message.contains('Permission being assigned already exists on the object')) { 
          Write-Warning 'Permission being assigned already exists on the object' 
        } else {
          throw $_
        }
      }
    }
  }
  End {}
}

# SIG # Begin signature block
# MIImwgYJKoZIhvcNAQcCoIImszCCJq8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUG3wemW8zfEcVFajdmoCGx6G5
# +vWggh/UMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0B
# AQwFADB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEh
# MB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAw
# MFoXDTI4MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IFJvb3QgUjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIE
# JHQu/xYjApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7
# fbu2ir29BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGr
# YbNzszwLDO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTH
# qi0Eq8Nq6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv
# 64IplXCN/7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2J
# mRCxrds+LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0P
# OM1nqFOI+rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXy
# bGWfv1VbHJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyhe
# Be6QTHrnxvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXyc
# uu7D1fkKdvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7id
# FT/+IAx1yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQY
# MBaAFKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJw
# IDaRXBeF5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmlj
# YXRlU2VydmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3Sa
# mES4aUa1qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+
# BtlcY2fUQBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8
# ZsBRNraJAlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx
# 2jLsFeSmTD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyo
# XZ3JHFuu2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p
# 1FiAhORFe1rYMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG
# 9w0BAQwFADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MS0wKwYDVQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYw
# HhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAmyudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxD
# eEDIArCS2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk
# 9vT0k2oWJMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7Xw
# iunD7mBxNtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ
# 0arWZVeffvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZX
# nYvZQgWx/SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+t
# AfiWu01TPhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvr
# n35XGf2RPaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn
# 3UayWW9bAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaR
# XBeF5jAdBgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYD
# VR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RS
# NDYuY3JsMHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEM
# BQADggIBAAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXK
# ZDk8+Y1LoNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWk
# vfPkKaAQsiqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3d
# MapandPfYgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwF
# kvjFV3jS49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZa
# PATHvNIzt+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8b
# kinLrYrKpii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7Ew
# oIJB0kak6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TW
# SenLbjBQUGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg
# 51Tbnio1lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoU
# KD85gnJ+t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGVjCCBL6g
# AwIBAgIQSLErKd7D+K4bkReO90aFWDANBgkqhkiG9w0BAQwFADBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTIyMDkxNDAwMDAwMFoXDTI1
# MDkxMzIzNTk1OVowTzELMAkGA1UEBhMCREUxEDAOBgNVBAgMB0hhbWJ1cmcxFjAU
# BgNVBAoMDVZpc29yaWFuIEdtYkgxFjAUBgNVBAMMDVZpc29yaWFuIEdtYkgwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/SsWhmbM7lO+pge5iLxuq3kXF
# 3xvbHU34E1wluLQOVC/A66AKKPo89E04zwAqqezN62flVYk9Xc+vFzNyy7I8wqq5
# vWojRnS7xW+QbFqJYxxHuGRiWEnt90p/wBrnq98Fl8JcmCKSDy/mUVAj+Lmq6WsU
# ph81PJMwC6T9POxk9/9k5I49Q8bBm5Yjx7yBTanHfdupCCFBgTFyJs9K4XLzva1I
# lCiMSYUxPRED0Dv8jVKdWnz3dbt00esUtubx5lD3YHdW6pYUR0hvJEi50G3sSqZ8
# Mebjts3+0PmEvHIR2aKvG/stx4jMngnBfwmeNbzWjwmqp4Qa4EGwv4Abs4hyK/kT
# erQua3IcXOgJqbblfxSoFDai14aCUGs2zxornoXhoYtjBj6XYgVS5eVME874hJLJ
# EZENiukta9r4IYOqnKglj+fwJrvEyx2INTELz99Ha074I8lG8ZJzNhuCqH6XgMUn
# 3EyOHMzbCrw1uDn0JDlhFX0sdaGXtopPgweIHbS87rcJc/tRSGhDG0YHqQWvxi9r
# Rb+v0L3KRYvtwih/VfpjQyFHFzcArDxKyrQ2SyGJ2ta0/Exl1dkYoTkVDm8R8f/2
# dG/VhTgvnDV1zW/SFRLwQAg/qmy6wpgK78338G+xCX47iauFtj2TAvw6sWB8jhwL
# xBvqvkP+r84HNB8KhQIDAQABo4IBpzCCAaMwHwYDVR0jBBgwFoAUDyrLIIcouOxv
# SK4rVKYpqhekzQwwHQYDVR0OBBYEFEHuYVgbSyoXa7Xei0crFprgrkXEMA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEoG
# A1UdIARDMEEwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8v
# c2VjdGlnby5jb20vQ1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2
# LmNybDB5BggrBgEFBQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2Vj
# dGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsG
# AQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAcBgNVHREEFTATgRFpbmZv
# QHZpc29yaWFuLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEASbJLCqUl82MPxtVDdBxd
# sOBCbYWxMvc4A9a/L+cuES3FYnBEa9jmA8o23+kvy2LZS3GeAU1AnNYkg2TAF+Oh
# fPDUviHUZDM/JgvCUF1ZmAvi6nLLBxvxfRxhGoUCkjaKIzDpPHZia6e/Jl9Xxthe
# GtCR9epTBuizMZTCTUvNPxY+Tm9L4EKHRsRBv8NkeuTKQpnGYfrHeKz/hVUeS4IS
# sTyv+xg7/nBITBSosfB79XDORaoNBxpqrSZLrpZV5OHIH2IGxRKKHyLVVCQAzriK
# +OV1EGBSmknqDarNbgtzU94iULYu15a1/PElzK7qB2i76FmLMMBVb9NVuXTfgMgT
# VzWfMs4mdsdOg7dcPxKpK2nViPbY3JQQVx8aKX+gJwWajuELP/JSE6nPYPSrwMLT
# xXRQ7AiScBTf6J3EeWq71AEUTSZ4/FImjbv0hDfnoSCr/6SRxc4it/kjXyJKXF1p
# VVbuEFsgyZpmxlSM3jSR9R02TrDR0q95oC/6eSwGxfwPMIIG7DCCBNSgAwIBAgIQ
# MA9vrN1mmHR8qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYD
# VQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBS
# U0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAyMDAwMDAwWhcNMzgw
# MTE4MjM1OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5j
# aGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9AZg/IJC9nIAhVJO5
# z6A+U++zWsB21hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9UyUnkuyWPCE5u2hj8B
# BZJmbyGr1XEQeYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzOWEnTv/M5u7mkI0Ks
# 0BXDf56iXNc48RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0BKLwPDU+zkQGObp0n
# dVXRFzs0IXuXAZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBgfrhN9Q0/29DqhYyK
# VnHRLZRMyIw80xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUXx7gpGaQpL0bj3duR
# X58/Nj4OMGcrRrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1IXMSHv2qyghYh3ek
# FesZVf/QOVQtJu5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0bdonigbSlofe6GsO
# 8Ft96XZpkyAcSpcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2fA179g6JTZ8qx+o2h
# ZMmIklnLqEbAyfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmLQTkUAx4p+hulIq6l
# w02C0I3aa7fb9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5WDLvbxhQiddPnTO9
# GrWdod6VQXqngwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHY
# m8Cd8rIDZsswHQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8GEgRVMA4GA1UdDwEB
# /wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBEGA1UdIAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3Js
# LnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0
# eS5jcmwwdgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVz
# ZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUH
# MAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIB
# AG1UgaUzXRbhtVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/RaoLlJWZApbGHLtVDb
# 4n35nwDvQMOt0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAcJlhc87QRD9XVw+K8
# 1Vh4v0h24URnbY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0llYIuM1cfwGWvnJS
# ajtCN3wWeDmTk5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbks8VmBvbz1kteraMr
# Qoohkv6ob1olcGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALWPncEvAQ2ted3y5wu
# jSMYuaPCRx3wXdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/RoZSmTqo9CfUFbLfS
# ZFrYKiLCS53xOV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1H3G/W0NdZT1QgW6r
# 8NDT/LKzH7aZlib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurwROYybxzrF06Uw3hl
# IDsPQaof6aFBnf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQxH/qEZ0eBsambTJd
# tDgJK0kHqv3sMNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsausfm2usg1XTN2jvF8
# IAwqd661ogKGuinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMIIG9TCCBN2gAwIBAgIQ
# OUwl4XygbSeoZeI72R0i1DANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEb
# MBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgw
# FgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRp
# bWUgU3RhbXBpbmcgQ0EwHhcNMjMwNTAzMDAwMDAwWhcNMzQwODAyMjM1OTU5WjBq
# MQswCQYDVQQGEwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMPU2Vj
# dGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5n
# IFNpZ25lciAjNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKSTKFJL
# zyeHdqQpHJk4wOcO1NEc7GjLAWTkis13sHFlgryf/Iu7u5WY+yURjlqICWYRFFiy
# uiJb5vYy8V0twHqiDuDgVmTtoeWBIHIgZEFsx8MI+vN9Xe8hmsJ+1yzDuhGYHvzT
# IAhCs1+/f4hYMqsws9iMepZKGRNcrPznq+kcFi6wsDiVSs+FUKtnAyWhuzjpD2+p
# WpqRKBM1uR/zPeEkyGuxmegN77tN5T2MVAOR0Pwtz1UzOHoJHAfRIuBjhqe+/dKD
# cxIUm5pMCUa9NLzhS1B7cuBb/Rm7HzxqGXtuuy1EKr48TMysigSTxleGoHM2K4GX
# +hubfoiH2FJ5if5udzfXu1Cf+hglTxPyXnypsSBaKaujQod34PRMAkjdWKVTpqOg
# 7RmWZRUpxe0zMCXmloOBmvZgZpBYB4DNQnWs+7SR0MXdAUBqtqgQ7vaNereeda/T
# pUsYoQyfV7BeJUeRdM11EtGcb+ReDZvsdSbu/tP1ki9ShejaRFEqoswAyodmQ6Mb
# AO+itZadYq0nC/IbSsnDlEI3iCCEqIeuw7ojcnv4VO/4ayewhfWnQ4XYKzl021p3
# AtGk+vXNnD3MH65R0Hts2B0tEUJTcXTC5TWqLVIS2SXP8NPQkUMS1zJ9mGzjd0HI
# /x8kVO9urcY+VXvxXIc6ZPFgSwVP77kv7AkTAgMBAAGjggGCMIIBfjAfBgNVHSME
# GDAWgBQaofhhGSAPw0F3RSiO0TVfBhIEVTAdBgNVHQ4EFgQUAw8xyJEqk71j89Fd
# TaQ0D9KVARgwDgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/
# BAwwCgYIKwYBBQUHAwgwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwgwJTAjBggr
# BgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQCMEQGA1Ud
# HwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRp
# bWVTdGFtcGluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPwYIKwYBBQUHMAKGM2h0
# dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNy
# dDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcN
# AQEMBQADggIBAEybZVj64HnP7xXDMm3eM5Hrd1ji673LSjx13n6UbcMixwSV32Vp
# YRMM9gye9YkgXsGHxwMkysel8Cbf+PgxZQ3g621RV6aMhFIIRhwqwt7y2opF8773
# 9i7Efu347Wi/elZI6WHlmjl3vL66kWSIdf9dhRY0J9Ipy//tLdr/vpMM7G2iDczD
# 8W69IZEaIwBSrZfUYngqhHmo1z2sIY9wwyR5OpfxDaOjW1PYqwC6WPs1gE9fKHFs
# GV7Cg3KQruDG2PKZ++q0kmV8B3w1RB2tWBhrYvvebMQKqWzTIUZw3C+NdUwjwkHQ
# epY7w0vdzZImdHZcN6CaJJ5OX07Tjw/lE09ZRGVLQ2TPSPhnZ7lNv8wNsTow0KE9
# SK16ZeTs3+AB8LMqSjmswaT5qX010DJAoLEZKhghssh9BXEaSyc2quCYHIN158d+
# S4RDzUP7kJd2KhKsQMFwW5kKQPqAbZRhe8huuchnZyRcUI0BIN4H9wHU+C4RzZ2D
# 5fjKJRxEPSflsIZHKgsbhHZ9e2hPjbf3E7TtoC3ucw/ZELqdmSx813UfjxDElOZ+
# JOWVSoiMJ9aFZh35rmR2kehI/shVCu0pwx/eOKbAFPsyPfipg2I2yMO+AIccq/pK
# QhyJA9z1XHxw2V14Tu6fXiDmCWp8KwijSPUV/ARP380hHHrl9Y4a1LlAMYIGWDCC
# BlQCAQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhBI
# sSsp3sP4rhuRF473RoVYMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKAC
# gAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQE/oLoAd2B220MBgx0U/Ry
# gmOwhDANBgkqhkiG9w0BAQEFAASCAgCXuwKumr76jtjKfhuYJc7qzIaJd4bETN5l
# FzC61ZJ01L2eSph++f4n0pqEl33eXaX1HKAyyRIEgGmCkEdqykhh76nTgn6f223h
# 6stkE/+l7o65+uMqHAX/CjPIBpR5DAUdxhO3jnpBYGTf+yNnN1Aag1VXf7QPsDIM
# jm6b1ztpFcuAwisJoaCOD5RLVrMMpyvCZoh6nI3wc+Tk68zeertXE4Q/mUYcagka
# dYoyftTrznYsydoazKr/ku6osreTPHDDwt4rTgyDnuCaCQz9IzxNzQ8m7gJYfe3l
# MXdsXCdw36Or4AmXX5TIdZPURXsU1xFDD+iP6/oiy/uiDqc0AeFIIcP88eRcKUXw
# skA//q1WnFTfYJ/T94VlMoNUGK87MM/KFitxLT0aRqXkJTTKGHm59JQI/WvasjCe
# mVMXi+MO3t2bmQ/azebv+ybDobWmoKpP/EeG0uBSr6wawyj6H4Ld7lAPxvlkH76J
# Dk6Kq9Gkb5MG89oInKurjsaReG+KEyNGSZL0Osib9ecGrSjg8chx37yttnwU7t8q
# RrnmoZ16bwVr1NKyaXCXiaJGdwZqXQgnLTZt2Iv8cKSOCpfJapovm1o89XO/QwrU
# A3/nEcMjyzNfmvpi/WqatNySqXyp0UX7rS+4U0bX48Et5hISlbzp38RxRXO3riMx
# XDCbwGkC6aGCA0swggNHBgkqhkiG9w0BCQYxggM4MIIDNAIBATCBkTB9MQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3Rp
# Z28gUlNBIFRpbWUgU3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQwDQYJYIZI
# AWUDBAICBQCgeTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJ
# BTEPFw0yNDAzMjcyMjU3MjVaMD8GCSqGSIb3DQEJBDEyBDB/E5OMU6OE5oQkBpff
# ECYelzLiGXDwUzX8WYKNX7wxQWvhZw8JYsYSfY8rN3+Yd50wDQYJKoZIhvcNAQEB
# BQAEggIAJQjoejPnlvYwvhO1IOK2Yyd63lcmCVFSq+CDrPhSdfrMqY/1gxUFFze9
# scwzShZ5zdUdgLFP2jIHNUd2cMxhlYTcejbU1kcTOSywJ0Y9XmWwi5YSnwcxRSnh
# 7VK6Rvaur36qoxv9RSTCrhAb5yiiDJ7VUJOz2MoOgYhGQadiUgfO9A3uCu6wlrXP
# I0jWpJVX0ROaMkNTIDtlI6xkVQE8tmo28HMpJOYKxrmMtJuk6zR9Fmni4evZjuvV
# vh+wk9dCy8GRoHbv0+lk96G3c0zF9qwejINurlNVlRbdX5GfctRkjWonHDTwu+pT
# l1RvXxOfOka7hsWVbcufJk8v+cmhu+8pEoQ7sG5RhUn32l0QaJoSi8jbdOUS+cpW
# fYAFuKyHbMzPVnmOSA5V7yDrH5KW+iOkjYZtIhc5Pu1RB1IdqhTdeRPL5pEZZGiJ
# Nd6XB0VCj4v0XgNkdr2K91Y/oegYbJxLg0SpCu/56km3PzG3naWL1eItNETt/sfP
# t3jOOW9N9MUPbhJdBWvZ4LbjT5gZqDPsrOtVWrcmtSfW12p7nglCu7LKgUIL2qn8
# 2hO8WVWrCTrQXv9yO4CmHcIoOhoEplygAC/bQQdv0eJtrFPo4KfQH9aehPOoyTVd
# e+d6y0eIdJqvrBlmP6mLJjFHQlRXARhdOXQB8VhFZ35PGIcfmu4=
# SIG # End signature block
