# Sourcegraph for PowerShell

[![powershellgallery](https://img.shields.io/powershellgallery/v/PSSourcegraph.svg)](https://www.powershellgallery.com/packages/PSSourcegraph)
[![downloads](https://img.shields.io/powershellgallery/dt/PSSourcegraph.svg?label=downloads)](https://www.powershellgallery.com/packages/PSSourcegraph)
[![build](https://travis-ci.org/sourcegraph/PSSourcegraph.svg?branch=master)](https://travis-ci.org/sourcegraph/PSSourcegraph)

Search Sourcegraph from PowerShell

![Text search output formatting](./images/textsearch.png)

![Symbol search output formatting](./images/symbolsearch.png)

Pretty formatting is supported for text, file and symbol results (`type:file` and `type:symbol`)

## Installation

```powershell
Install-Module PSSourcegraph
```

## Included

- `Search-Sourcegraph` with autocompletion
- `Disable-SourcegraphRepository`
- `Enable-SourcegraphRepository`
- `Get-SourcegraphRepository`
- `Get-SourcegraphUser`
- `New-SourcegraphUser`
- `Invoke-SourcegraphApiRequest`

Missing something? Please file an issue!

## Configuration

You can configure a default endpoint and token to be used by modifying `$PSDefaultParameterValues` in your `$PROFILE`:

```powershell
$PSDefaultParameterValues['*Sourcegraph*:Token'] = '5c01fd47a2b2187c2947f8a2eb76b358f3ed0e26'
$PSDefaultParameterValues['*Sourcegraph*:Endpoint'] = 'https://sourcegraph.example.com'
```
