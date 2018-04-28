
# Sourcegraph for PowerShell

[![powershellgallery](https://img.shields.io/powershellgallery/v/Sourcegraph.svg)](https://www.powershellgallery.com/packages/Sourcegraph)
[![downloads](https://img.shields.io/powershellgallery/dt/Sourcegraph.svg?label=downloads)](https://www.powershellgallery.com/packages/Sourcegraph)

## Installation

```powershell
Install-Module Sourcegraph
```

## Usage example

```powershell
Invoke-SourcegraphApiRequest -Variables @{query = 'repogroup:sample test'} -Query @'
    query($query: String!) {
        search(query: $query) {
            results {
                resultCount
            }
        }
    }
'@
```

See `Get-Help Invoke-SourcegraphApiRequest` for detailed documentation.

## Configuration

You can configure a default endpoint and token to be used by modifying `$PSDefaultParameterValues` in your `$PROFILE`:

```powershell
$PSDefaultParameterValues['*Sourcegraph*:Token'] = '5c01fd47a2b2187c2947f8a2eb76b358f3ed0e26'
$PSDefaultParameterValues['*Sourcegraph*:Endpoint'] = 'https://sourcegraph.example.com'
```
