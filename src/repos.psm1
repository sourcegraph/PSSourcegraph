
$repositoryFields = Get-Content -Raw "$PSScriptRoot/queries/RepositoryFields.graphql"
$repositoryQuery = (Get-Content -Raw "$PSScriptRoot/queries/Repository.graphql") + $repositoryFields
$repositoriesQuery = (Get-Content -Raw "$PSScriptRoot/queries/Repositories.graphql") + $repositoryFields
function Get-SourcegraphRepository {
    <#
    .SYNOPSIS
        List all repositories known to a Sourcegraph instance
    .DESCRIPTION
        Lists all repositories known to a Sourcegraph instance by querying its API.
    .PARAMETER Id
        Get a repository by its ID
    .PARAMETER Name
        Return repositories with the given names
    .PARAMETER CloneUrl
        Get a repository by a git clone URL
    .PARAMETER Query
        Return repositories whose names match the query
    .PARAMETER SortBy
        By what to sort
    .PARAMETER Descending
        Sort descending
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsPaging)]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Name,
        [string] $CloneUrl,
        [string] $Query,

        [ValidateSet('REPOSITORY_NAME', 'REPOSITORY_CREATED_AT')]
        [string] $SortBy = 'REPOSITORY_NAME',
        [switch] $Descending,

        [Uri] $Endpoint = 'https://sourcegraph.com',
        [SecureString] $Token
    )
    process {
        if ($Id -or $CloneUrl) {
            $vars = @{
                id       = $Id
                cloneUrl = $CloneUrl
            }
            $data = Invoke-SourcegraphApiRequest -Query $repositoryQuery -Variables $vars -Endpoint $Endpoint -Token $Token
            $data.repository
            if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                $count = if ($data.repository) { 1 } else { 0 }
                $PSCmdlet.PagingParameters.NewTotalCount($count, 1)
            }
        } else {
            $first = if ($PSCmdlet.PagingParameters.First -eq [uint64]::MaxValue) {
                $null
            } else {
                $PSCmdlet.PagingParameters.Skip + $PSCmdlet.PagingParameters.First
            }
            $vars = @{
                first      = $first
                query      = $Query
                names      = $Name
                orderBy    = $SortBy
                descending = [bool]$Descending
            }
            $data = Invoke-SourcegraphApiRequest -Query $repositoriesQuery -Variables $vars -Endpoint $Endpoint -Token $Token
            if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                $PSCmdlet.PagingParameters.NewTotalCount($data.repositories.totalCount, 1)
            }
            $data.repositories.nodes | Select-Object -Skip $PSCmdlet.PagingParameters.Skip
        }
    }
}
Set-Alias Get-SrcRepository Get-SourcegraphRepository
