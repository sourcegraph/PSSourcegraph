$HoverQuery = Get-Content -Raw "$PSScriptRoot/queries/Hover.graphql"
$DefinitionQuery = Get-Content -Raw "$PSScriptRoot/queries/Definition.graphql"
$ReferenceQuery = Get-Content -Raw "$PSScriptRoot/queries/Reference.graphql"

function Get-SourcegraphHover {
    <#
    .SYNOPSIS
        Gets the hover content for a token at a given position in a file.
    .DESCRIPTION
        Queries LSIF data known to Sourcegraph to get the hover content for a token at a given position in a file.
        The output will be displayed as rendered markdown.
    .PARAMETER RepositoryName
        The name of the repository.
    .PARAMETER Revision
        The optional revision.
    .PARAMETER Path
        The file path of the token.
    .PARAMETER LineNumber
        The 0-based line number of the token.
    .PARAMETER CharacterNumber
        The 0-based character number of the token (or multiple).
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    .INPUTS
        Sourcegraph.LineMatch. You can pipe text and symbol search results to this command.
    .OUTPUTS
        Sourcegraph.Location
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $RepositoryName,

        [Alias('Sha')]
        [Alias('CommitID')]
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Revision = 'HEAD',

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string] $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int] $LineNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int[]] $CharacterNumber, # Supports multiple character numbers to support piping a LineMatch

        [Uri] $Endpoint = 'https://sourcegraph.com',
        [SecureString] $Token
    )

    process {
        $CharacterNumber | ForEach-Object {
            $variables = @{
                repository = $RepositoryName
                rev = $Revision
                path = $Path
                line = $LineNumber
                character = $_
            }
            $data = Invoke-SourcegraphApiRequest -Query $HoverQuery -Variables $variables -Endpoint $Endpoint -Token $Token
            if (!$data.repository) {
                Write-Error "Repository $RepositoryName not found"
                return
            }
            if (!$data.repository.commit) {
                Write-Error "Revision $Revision not found in repository $RepositoryName"
                return
            }
            if (!$data.repository.commit.blob) {
                Write-Error "File $Path not found in repository $RepositoryName at revision $Revision"
                return
            }
            if (!$data.repository.commit.blob.lsif) {
                Write-Error "No LSIF data available for repository $RepositoryName at revision $Revision"
                return
            }
            $hover = $data.repository.commit.blob.lsif.hover
            if (!$hover) {
                return
            }
            $hover.PSObject.TypeNames.Insert(0, 'Sourcegraph.Hover')
            return $hover
        }
    }
}
Set-Alias Get-SrcHover Get-SourcegraphHover

function Get-SourcegraphDefinition {
    <#
    .SYNOPSIS
        Gets the definition location for a token at a given position in a file.
    .DESCRIPTION
        Queries LSIF data known to Sourcegraph to get the definition location for a token at a given position in a file.
    .PARAMETER RepositoryName
        The name of the repository.
    .PARAMETER Revision
        The optional revision.
    .PARAMETER Path
        The file path of the token.
    .PARAMETER LineNumber
        The 0-based line number of the token.
    .PARAMETER CharacterNumber
        The 0-based character number of the token (or multiple).
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    .INPUTS
        Sourcegraph.LineMatch. You can pipe text and symbol search results to this command.
    .OUTPUTS
        Sourcegraph.Location
    #>
    [CmdletBinding()]
    param(
        [Uri] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $RepositoryName,

        [Alias('Sha')]
        [Alias('CommitID')]
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Revision = 'HEAD',

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string] $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int] $LineNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int[]] $CharacterNumber, # Supports multiple character numbers to support piping a LineMatch

        [ValidateNotNullOrEmpty()]
        [SecureString] $Token
    )

    process {
        $CharacterNumber |
            ForEach-Object {
                $variables = [pscustomobject]@{
                    repository = $RepositoryName
                    rev = $Revision
                    path = $Path
                    line = $LineNumber
                    character = $_
                }
                $data = Invoke-SourcegraphApiRequest -Query $DefinitionQuery -Variables $variables -Endpoint $Endpoint -Token $Token
                if (!$data.repository) {
                    Write-Error "Repository $RepositoryName not found"
                    return
                }
                if (!$data.repository.commit) {
                    Write-Error "Revision $Revision not found in repository $RepositoryName"
                    return
                }
                if (!$data.repository.commit.blob) {
                    Write-Error "File $Path not found in repository $RepositoryName at revision $Revision"
                    return
                }
                if (!$data.repository.commit.blob.lsif) {
                    Write-Error "No LSIF data available for repository $RepositoryName at revision $Revision"
                    return
                }
                $connection = $data.repository.commit.blob.lsif.definitions
                $connection.nodes
            } |
            ForEach-Object {
                $_.Url = [Uri]::new($Endpoint, $_.url)
                $_.PSObject.TypeNames.Insert(0, 'Sourcegraph.Location')
                $_
            }
    }
}
Set-Alias Get-SrcDefinition Get-SourcegraphDefinition

function Get-SourcegraphReference {
    <#
    .SYNOPSIS
        Gets the reference locations for a given position in a file.
    .DESCRIPTION
        Queries LSIF data known to Sourcegraph to get the locations of all known references to a token at a given position in a file.
        The references are paginated automatically and streamed to the pipeline, use Select-Object -First to limit.
    .PARAMETER RepositoryName
        The name of the repository.
    .PARAMETER Revision
        The optional revision.
    .PARAMETER Path
        The file path of the token.
    .PARAMETER LineNumber
        The 0-based line number of the token.
    .PARAMETER CharacterNumber
        The 0-based character number of the token (or multiple).
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    .INPUTS
        Sourcegraph.LineMatch. You can pipe text and symbol search results to this command.
    .OUTPUTS
        Sourcegraph.Location
    #>
    [CmdletBinding()]
    param(
        [Uri] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $RepositoryName,

        [Alias('Sha')]
        [Alias('CommitID')]
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Revision = 'HEAD',

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('FilePath')]
        [string] $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int] $LineNumber,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int[]] $CharacterNumber, # Supports multiple character numbers to support piping a LineMatch

        [int] $PageSize = 50,

        [ValidateNotNullOrEmpty()]
        [SecureString] $Token
    )

    process {
        $CharacterNumber |
            ForEach-Object {
                $variables = [pscustomobject]@{
                    repository = $RepositoryName
                    rev = $Revision
                    path = $Path
                    line = $LineNumber
                    character = $_
                    first = $PageSize
                    after = $null
                }
                while ($true) {
                    $data = Invoke-SourcegraphApiRequest -Query $ReferenceQuery -Variables $variables -Endpoint $Endpoint -Token $Token
                    if (!$data.repository) {
                        Write-Error "Repository $RepositoryName not found"
                        return
                    }
                    if (!$data.repository.commit) {
                        Write-Error "Revision $Revision not found in repository $RepositoryName"
                        return
                    }
                    if (!$data.repository.commit.blob) {
                        Write-Error "File $Path not found in repository $RepositoryName at revision $Revision"
                        return
                    }
                    if (!$data.repository.commit.blob.lsif) {
                        Write-Error "No LSIF data available for repository $RepositoryName at revision $Revision"
                        return
                    }
                    $connection = $data.repository.commit.blob.lsif.references
                    $connection.nodes
                    if (-not $connection.pageInfo.hasNextPage) {
                        break
                    }
                    $variables.after = $connection.pageInfo.endCursor
                }
            } |
            ForEach-Object {
                # Make URL absolute and make sure link detectors in terminals can detect it (specifically VS Code)
                $_.Url = [Uri]::new($Endpoint, $_.url)
                $_.PSObject.TypeNames.Insert(0, 'Sourcegraph.Location')
                $_
            }
    }
}
Set-Alias Get-SrcReference Get-SourcegraphReference
