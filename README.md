# AzureApiUtils module

![PowerShell Gallery Version (including pre-releases)](https://img.shields.io/powershellgallery/v/AzureApiUtils?labelColor=181818&color=4578d2&label=PS%20Gallery%20Version)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AzureApiUtils?labelColor=181818&color=4578d2&label=PS%20Gallery%20Downloads)
![Code Coverage](https://img.shields.io/badge/coverage-96.15%25-yellow?labelColor=181818&color=4578d2&label=Test%20Coverage)

## Features

- ✨ Automatic retry and pagination handling
- 💪 Easy interactions with Azure and Graph APIs
- 🚀 Simplified permission management for Managed Identities

## Installation

```PowerShell
Install-Module AzureApiUtils
```

## First steps

Before using the functions in this module, you need to install and import the `Microsoft.Graph.Authentication` module, which is used for authenticating to the Graph API.

```powershell
Install-Module Microsoft.Graph.Authentication
```

You also need to authenticate to the Graph API using the `Connect-MgGraph` cmdlet. This needs to be done in the same session where you plan to use the `AzureApiUtils` functions.

```powershell
Connect-MgGraph
```

### Available functions

- `Add-AppPermission`: Adds application permissions to an app in Entra ID. Made to simplify permission management with Managed Identities. 
- `Get-AppPermission`: Retrieves application permissions from an app in Entra ID. Made to simplify permission management with Managed Identities. 
- `Remove-AppPermission`: Removes application permissions from an app in Entra ID. Made to simplify permission management with Managed Identities. 
- `Invoke-AzureRequest`: Invokes a request to Azure and handles pagination. Is a high level wrapper around `Invoke-RetryRequest`, you normally only need this.
- `Invoke-GraphApiRequest`: Invokes a Graph API request. Is a high level wrapper around `Invoke-GraphApiRetryRequest`, with support for pagination. You normally only need this
- `Invoke-GraphApiRetryRequest`: Invokes a Graph API request with retry logic for rate limiting.
- `Invoke-RetryRequest`: Invokes a request with retry logic for rate limiting.
- `New-AuthorizationHeader`: Generates an authorization header for HTTP requests.

### Available functions

<details>
<summary>Function list</summary>

- Add-AppPermission
- Get-AppPermission
- Invoke-AzureRequest
- Invoke-GraphApiRequest
- Invoke-GraphApiRetryRequest
- Invoke-RetryRequest
- New-AuthorizationHeader
- Remove-AppPermission

</details>

## Contribution

See [Contributing Guide](https://github.com/itpropro/AzureApiUtils/blob/main/CONTRIBUTING.md).

## License

Made with :heart:

Published under [MIT License](./LICENCE).
