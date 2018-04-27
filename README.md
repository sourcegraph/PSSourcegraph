
# Sourcegraph for PowerShell

## Installation

```powershell
Install-Module -Scope CurrentUser Sourcegraph
```

## Usage

```powershell
Invoke-SourcegraphApiRequest [-Query] <string> -Token <string> [-Endpoint <string>] [-Variables <hashtable>]  [<CommonParameters>]
```

Aliases: `Invoke-SGApiRequest`

## Configuration

Add this to your `$PROFILE`:

```powershell
$PSDefaultParameterValues['*Sourcegraph*:Token'] = 'your default token'
$PSDefaultParameterValues['*Sourcegraph*:Endpoint'] = 'your default endpoint (default https://sourcegraph.com/.api/graphql)'
```
