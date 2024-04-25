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
# MIIVrwYJKoZIhvcNAQcCoIIVoDCCFZwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChmbRIVDgdhpEb
# /k2VOaUTFTPopIMHrOyyGvFv4qvYX6CCEeswggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZWMIIEvqADAgECAhBIsSsp3sP4rhuRF473RoVYMA0GCSqG
# SIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYw
# HhcNMjIwOTE0MDAwMDAwWhcNMjUwOTEzMjM1OTU5WjBPMQswCQYDVQQGEwJERTEQ
# MA4GA1UECAwHSGFtYnVyZzEWMBQGA1UECgwNVmlzb3JpYW4gR21iSDEWMBQGA1UE
# AwwNVmlzb3JpYW4gR21iSDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AL9KxaGZszuU76mB7mIvG6reRcXfG9sdTfgTXCW4tA5UL8DroAoo+jz0TTjPACqp
# 7M3rZ+VViT1dz68XM3LLsjzCqrm9aiNGdLvFb5BsWoljHEe4ZGJYSe33Sn/AGuer
# 3wWXwlyYIpIPL+ZRUCP4uarpaxSmHzU8kzALpP087GT3/2Tkjj1DxsGbliPHvIFN
# qcd926kIIUGBMXImz0rhcvO9rUiUKIxJhTE9EQPQO/yNUp1afPd1u3TR6xS25vHm
# UPdgd1bqlhRHSG8kSLnQbexKpnwx5uO2zf7Q+YS8chHZoq8b+y3HiMyeCcF/CZ41
# vNaPCaqnhBrgQbC/gBuziHIr+RN6tC5rchxc6AmptuV/FKgUNqLXhoJQazbPGiue
# heGhi2MGPpdiBVLl5UwTzviEkskRkQ2K6S1r2vghg6qcqCWP5/Amu8TLHYg1MQvP
# 30drTvgjyUbxknM2G4KofpeAxSfcTI4czNsKvDW4OfQkOWEVfSx1oZe2ik+DB4gd
# tLzutwlz+1FIaEMbRgepBa/GL2tFv6/QvcpFi+3CKH9V+mNDIUcXNwCsPErKtDZL
# IYna1rT8TGXV2RihORUObxHx//Z0b9WFOC+cNXXNb9IVEvBACD+qbLrCmArvzffw
# b7EJfjuJq4W2PZMC/DqxYHyOHAvEG+q+Q/6vzgc0HwqFAgMBAAGjggGnMIIBozAf
# BgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUQe5hWBtL
# Khdrtd6LRysWmuCuRcQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAj
# BggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEkG
# A1UdHwRCMEAwPqA8oDqGOGh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3JsMHkGCCsGAQUFBwEBBG0wazBEBggrBgEF
# BQcwAoY4aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNp
# Z25pbmdDQVIzNi5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28u
# Y29tMBwGA1UdEQQVMBOBEWluZm9Admlzb3JpYW4uY29tMA0GCSqGSIb3DQEBDAUA
# A4IBgQBJsksKpSXzYw/G1UN0HF2w4EJthbEy9zgD1r8v5y4RLcVicERr2OYDyjbf
# 6S/LYtlLcZ4BTUCc1iSDZMAX46F88NS+IdRkMz8mC8JQXVmYC+LqcssHG/F9HGEa
# hQKSNoojMOk8dmJrp78mX1fG2F4a0JH16lMG6LMxlMJNS80/Fj5Ob0vgQodGxEG/
# w2R65MpCmcZh+sd4rP+FVR5LghKxPK/7GDv+cEhMFKix8Hv1cM5Fqg0HGmqtJkuu
# llXk4cgfYgbFEoofItVUJADOuIr45XUQYFKaSeoNqs1uC3NT3iJQti7XlrX88SXM
# ruoHaLvoWYswwFVv01W5dN+AyBNXNZ8yziZ2x06Dt1w/EqkradWI9tjclBBXHxop
# f6AnBZqO4Qs/8lITqc9g9KvAwtPFdFDsCJJwFN/oncR5arvUARRNJnj8UiaNu/SE
# N+ehIKv/pJHFziK3+SNfIkpcXWlVVu4QWyDJmmbGVIzeNJH1HTZOsNHSr3mgL/p5
# LAbF/A8xggMaMIIDFgIBATBoMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0
# aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmlu
# ZyBDQSBSMzYCEEixKynew/iuG5EXjvdGhVgwDQYJYIZIAWUDBAIBBQCggYQwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg
# nlefdHtVwhg5fspfhlMup2Be2vHRmNp2DoJGN9NsYvswDQYJKoZIhvcNAQEBBQAE
# ggIAd4k0y0xtTEJReROr61Obj6oidMTBVcuCxom5mvQH65sw9FfNrsO5b/xNH5dL
# 809MiNNSbm5rCsMRNKeMYfN86JjgQMpjI7UgOFjNOimE3qES4lCNl52bl0tj14oq
# J/BUk/drKDP/IO2hBPGHarlcxTOKesNlFAJLZIib8GasBe7aa+mk4KMMeAYoKxdz
# O624tpy2yKOzJBo3sGKmWlPoJEN++Vmqcm2X94vEmPTxb2+rDz57udxEKPybrtL2
# Lv+aeToeMT56c7+YXM2pNFr3lH/dAEHoOJeXej4iwXBtASeP6633cZQjTUZ2MEJ5
# IYvTuc7x+DgmkAejHOP34SaDbtEkAGjbZUt9AsDKMaj7rADMKdNY9gJStRXAawVY
# 08PPc3yMMguo3/ZOM00rLDPfWQeEGIswopLPtFxU8Yy9TQ+6T7n+NH+yxY5Mkjqw
# SGWSYCbdokDYmU3FxkoFhBRvJheiHjvU6hhb/orR1+gYsHI3K7hX34BeyuUn7JMB
# UK418hw1gAiBMyG2GEi5TZ3QCpQPn56jAxqLJW75i21AM4d6Y4kDquYVCKDbab4S
# h6jEinEWlpibqBQMQu49YlvbsG+VKiJyA5/griVAbq9bkZxoSjz9Vxql/yvonHUG
# H8cupQVqQXme12dibrvgH7ZdIW2ioAyKREyWewAXdP8K2MI=
# SIG # End signature block
