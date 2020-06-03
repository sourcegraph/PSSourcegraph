Import-Module -Scope Local "$PSScriptRoot/api.psm1"

$RepositoryFields = Get-Content -Raw "$PSScriptRoot/../queries/RepositoryFields.graphql"
$SearchQuery = (Get-Content -Raw "$PSScriptRoot/../queries/Search.graphql") + $RepositoryFields
$SuggestionsQuery = (Get-Content -Raw "$PSScriptRoot/../queries/Suggestions.graphql")

# Note: The default name of this function is Search-Sourcegraph,
# the prefix/suffix is added automatically as configured in PSSourcegraph.psd1
# or overridden when calling Import-Module.
function Search- {
    <#
    .SYNOPSIS
        Get users on a Sourcegraph instance
    .PARAMETER Query
        The search query.
    .PARAMETER CaseSensitive
        Match the query case-sensitive. Only for regexp and literal search.
    .PARAMETER Structural
        Interpret the query as a structural search query.
    .PARAMETER RegularExpression
        Interpret the query as a regular expression.
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'literal')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Query,

        [Parameter(ParameterSetName = 'regexp')]
        [Parameter(ParameterSetName = 'literal')]
        [switch] $CaseSensitive,

        [Parameter(ParameterSetName = 'regexp', Mandatory)]
        [Alias('Regexp')]
        [switch] $RegularExpression,

        [Parameter(ParameterSetName = 'structural', Mandatory)]
        [switch] $Structural,

        [Uri] $Endpoint = 'https://sourcegraph.com',
        [SecureString] $Token
    )

    process {
        if ($CaseSensitive) {
            $Query += ' case:yes'
        }
        $variables = @{
            query = $Query
            patternType = $PSCmdlet.ParameterSetName
        }
        $data = Invoke-ApiRequest -Query $SearchQuery -Variables $variables -Endpoint $Endpoint -Token $Token
        if ($data.search.results.cloning.Count -gt 0) {
            Write-Warning "Cloning:"
            $data.search.results.cloning.name | Write-Warning
        }
        if ($data.search.results.missing.Count -gt 0) {
            Write-Warning "Missing:"
            $data.search.results.missing.name | Write-Warning
        }
        if ($data.search.results.timedout.Count -gt 0) {
            Write-Warning "Timed out:"
            $data.search.results.timedout.name | Write-Warning
        }
        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            $PSCmdlet.PagingParameters.NewTotalCount($data.search.results.resultCount, 1)
        }
        if ($data.search.results.limitHit) {
            Write-Warning "Result limit hit"
        }

        foreach ($result in $data.search.results.results) {
            $result.PSObject.TypeNames.Insert(0, 'Sourcegraph.' + $result.__typename)
            # Make the metadata accessible from the match objects
            Add-Member -InputObject $result -MemberType NoteProperty -Name 'SearchResults' -Value $data.search.results
            if ($result.__typename -eq 'FileMatch') {
                # Make URL absolute
                $result.File.Url = [Uri]::new($Endpoint, $result.File.Url)
                $result.Repository.Url = [Uri]::new($Endpoint, $result.Repository.Url)

                if ($result.LineMatches -or $result.Symbols) {
                    # Instead of nesting LineMatches and Symbols in FileMatches, we flat out the list and let PowerShell formatting do the grouping
                    foreach ($lineMatch in $result.LineMatches) {
                        $lineMatch.PSObject.TypeNames.Insert(0, 'Sourcegraph.LineMatch')
                        Add-Member -InputObject $lineMatch -MemberType NoteProperty -Name 'FileMatch' -Value $result
                        $lineMatch
                    }
                    foreach ($symbol in $result.Symbols) {
                        $symbol.PSObject.TypeNames.Insert(0, 'Sourcegraph.Symbol')
                        Add-Member -InputObject $symbol -MemberType NoteProperty -Name 'FileMatch' -Value $result
                        $symbol
                    }
                } else {
                    # The FileMatch has no line or symbol matches, which means the file name matched, so add the FileMatch itself as a result
                    $result
                }
            } else {
                $result
            }
        }
    }
}
Export-ModuleMember -Function Search-

function Get-SearchSuggestions {
    [CmdletBinding(DefaultParameterSetName = 'literal')]
    param (
        [Parameter(Mandatory)]
        [string] $Query,

        [Parameter(ParameterSetName = 'regexp')]
        [Parameter(ParameterSetName = 'literal')]
        [switch] $CaseSensitive,

        [Parameter(ParameterSetName = 'regexp', Mandatory)]
        [Alias('Regexp')]
        [switch] $RegularExpression,

        [Parameter(ParameterSetName = 'structural', Mandatory)]
        [switch] $Structural,

        [Uri] $Endpoint = 'https://sourcegraph.com',
        [SecureString] $Token
    )

    process {
        if ($CaseSensitive) {
            $Query += ' case:yes'
        }
        $vars = @{
            query = $Query
            first = 10
            patternType = $PSCmdlet.ParameterSetName
        }
        Invoke-ApiRequest -Query $SuggestionsQuery -Variables $vars -Endpoint $Endpoint -Token $Token |
            ForEach-Object { $_.search.suggestions }
    }
}

# Merges two potentially overlapping strings
function Merge-Strings([string] $a, [string] $b) {
    for ($i = $b.Length; $i -gt 0; $i--) {
        if ($a.EndsWith($b.Substring(0, $i))) {
            return $a.Substring(0, $a.Length - $i) + $b
        }
    }
    # replace last word
    return ($a -replace "\b\S*$", "") + $b
}

Register-ArgumentCompleter -CommandName Search-Sourcegraph -ParameterName Query -ScriptBlock {
    [CmdletBinding()]
    param([string]$command, [string]$parameter, [string]$wordToComplete, [CommandAst]$commandAst, [Hashtable]$params)

    $suggestionParams = @{}
    if ($params.ContainsKey('Token')) {
        $suggestionParams.Token = $params.Token
    }
    if ($params.ContainsKey('Endpoint')) {
        $suggestionParams.Endpoint = $params.Endpoint
    }
    if ($params.ContainsKey('CaseSensitive')) {
        $suggestionParams.CaseSensitive = $params.CaseSensitive
    }
    if ($params.ContainsKey('RegularExpression')) {
        $suggestionParams.RegularExpression = $params.RegularExpression
    }
    if ($params.ContainsKey('Structural')) {
        $suggestionParams.Structural = $params.Structural
    }

    Get-SourcegraphSearchSuggestions @suggestionParams -Query $wordToComplete.Trim(@("'", '"')) |
        ForEach-Object {
            $suggestion = $_
            $insertText, $tooltip = switch ($suggestion.__typename) {
                'Repository' {
                    'repo:' + $suggestion.Name
                    "Repository $($suggestion.Name)"
                }
                'File' {
                    'file:' + $suggestion.Path
                    "File $($suggestion.Name)"
                }
                'Symbol' {
                    $suggestion.Name
                    $kind = $suggestion.Kind[0] + $suggestion.Kind.Substring(1).ToLower()
                    "$kind symbol $($suggestion.Name)`n$($suggestion.Location.Resource.Path)"
                }
            }
            $replaceText = Merge-Strings $wordToComplete.TrimEnd(@('"', "'")) $insertText
            [CompletionResult]::new($replaceText, $suggestion.Name, [CompletionResultType]::ParameterValue, $tooltip)
        }
}
