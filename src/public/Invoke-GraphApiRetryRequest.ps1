<#
.SYNOPSIS
  This function invokes a Graph API request with retry logic for rate limiting (HTTP 429 responses).

.DESCRIPTION
  The Invoke-GraphApiRetryRequest function sends a request to the Graph API using the provided parameters. 
  If the API returns a 429 response (Too Many Requests), the function will wait and retry the request. 
  The wait time increases exponentially with each subsequent 429 response (exponential backoff).

.PARAMETER method
  Optional. The HTTP method to use for the request. Defaults to 'get'.

.PARAMETER uri
  Mandatory. The URI of the Graph API endpoint to which the request will be sent.

.PARAMETER body
  Optional. The body of the request, if applicable, if method is get, used as query parameter.

.EXAMPLE
  Invoke-GraphApiRetryRequest -uri "/beta/users" -method "get"
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
      Invoke-MgGraphRequest -Method $method -Uri $uri -Body $body -ErrorAction Stop
    }
    catch {
      if ($_.Exception.Response.StatusCode.value__ -ne 429) { $retry = $false; throw $_ }
      $sleepDuration = $sleepDuration -eq 0 ? 4 : $sleepDuration * 2
      $retry = $true
      Write-Verbose "API returned 429, retrying in $sleepDuration seconds"
      Start-Sleep -Seconds $sleepDuration
    }
  } until (
    -not $retry
  )
}

# SIG # Begin signature block
# MIIVrwYJKoZIhvcNAQcCoIIVoDCCFZwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCdGRDM6fsRKZ11
# plWezzfb2MqBXtEuZ5z+akmzBewMW6CCEeswggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# Mg2z777a3aR58hIX17A2xEfp3qCT2sF32isplHP+PrYwDQYJKoZIhvcNAQEBBQAE
# ggIAidK07LWW1PNxsEdcscSneJWAty8tdXhgXE7zO9at5Asw7JXEbb1SvKlYPsGH
# R+dAGHmgG3DRnrpQAIPPocDUM2KySjEUTigIGynxK57fNdHqJL+RcDGpHHLhHbH0
# Vny5hNHU+miUBj877hQn9Idx4TEH76R4QQZNl7947OqtN72QZqkgWhPvMR6TsIHe
# tcdramm/2f3mQSEGNZ34osdj9oDP2r622e/yjq/w15NJZzsJSxMkn6a01HbHcqu2
# 8yCeOt94zb/FmtQEKNd6PE6RQbEp/mXmi3mMmkpCtXBtdDzIRcmE0ttXHRM8i17q
# 8ixInpWSeq2KPCkrw0iIRpxu/l6Ec8XMp/h1L5DfzSsLpV0TrO1zhThF3Yc1ii09
# TizDWG2KRHDaCu+sf8H+U4C8cK5lVIb88CfIqdmnVAVJEFcboPROc7QNbfh6SOhP
# PmGOdTHm+rztTn8xYdFtbrp5KL+XgDPgZ8PlD0PZxl3H19QsOYcY89hzTGDY5N4x
# Np9CA0zh0NlqVf4SE9S8FEBKGfiqxM0x+C5C+R3pIpnox1DbJVktU0NopLj9kvbt
# zQwbxhZKgssv01tW6GJ65FnxNpugnsDC7Q2l+sDIAeozPl5msSWheB668wNGljOs
# ncg9vA1a2DCMkzf43zM5FtgLcgtCzucumh/XbH4eugCZhbE=
# SIG # End signature block
