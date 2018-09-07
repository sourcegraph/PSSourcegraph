
$repositoriesQuery = Get-Content -Raw "$PSScriptRoot/queries/Repositories.graphql"

function Get-SourcegraphRepository {
    <#
    .SYNOPSIS
        List all repositories known to a Sourcegraph instance
    .DESCRIPTION
        Lists all repositories known to a Sourcegraph instance by querying its API.
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsShouldProcess, SupportsPaging)]
    param(
        [string] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    $data = Invoke-SourcegraphApiRequest -Query $repositoriesQuery -Endpoint $Endpoint -Token $Token
    if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
        $PSCmdlet.PagingParameters.NewTotalCount($data.repositories.totalCount, 1)
    }
    $data.repositories.nodes
}
Set-Alias Get-SrcRepositories Get-SourcegraphRepositories

$setRepositoryEnabledQuery = Get-Content -Raw "$PSScriptRoot/queries/SetRepositoryEnabled.graphql"

function Enable-SourcegraphRepository {
    <#
    .SYNOPSIS
        Enables a repository on a Sourcegraph instance
    .DESCRIPTION
        Enables a repository on a Sourcegraph instance
    .PARAMETER Id
        The ID of the repository
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [string] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    Invoke-SourcegraphApiRequest -Query $setRepositoryEnabledQuery -Variables @{repo = $Id; enabled = $true} -Endpoint $Endpoint -Token $Token | Out-Null
}
Set-Alias Enable-SrcRepository Enable-SourcegraphRepository

function Disable-SourcegraphRepository {
    <#
    .SYNOPSIS
        Disables a repository on a Sourcegraph instance
    .DESCRIPTION
        Disables a repository on a Sourcegraph instance
    .PARAMETER Id
        The ID of the repository
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Id,

        [string] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    Invoke-SourcegraphApiRequest -Query $setRepositoryEnabledQuery -Variables @{repo = $Id; enabled = $false} -Endpoint $Endpoint -Token $Token | Out-Null
}
Set-Alias Disable-SrcRepository Disable-SourcegraphRepository
