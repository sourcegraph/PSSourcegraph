
function Invoke-SourcegraphApiRequest {
    <#
    .SYNOPSIS
        Invoke an API Request to the Sourcegraph GraphQL API
    .DESCRIPTION
        Invoke an API Request to the Sourcegraph GraphQL API and returns the result data.
        Errors are written to the error pipeline.
    .PARAMETER Query
        The GraphQL query
    .PARAMETER Variables
        Values to replace the variables in the GraphQL query with
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    .EXAMPLE
        C:\PS> Invoke-SourcegraphApiRequest 'query { currentUser { username } }'

        Echo back the username of the authenticated user
    .EXAMPLE
        C:\PS> Invoke-SourcegraphApiRequest 'query($query: String) { search(query: $query) { results { resultCount } } }' @{query = 'repogroup:sample test'}

        Search the repogroup "sample" for the term "test"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Query,

        [Parameter(Position = 1)]
        $Variables = @{},

        [string] $Endpoint = 'https://sourcegraph.com',

        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    $uri = New-Object System.Uri (New-Object System.Uri $Endpoint), '/.api/graphql' -ErrorAction Stop
    $header = @{
        "Authorization" = "token $Token"
        "User-Agent"    = "Sourcegraph for PowerShell"
    }
    $body = @{
        query     = $Query
        variables = $Variables
    }
    $parsed = Invoke-RestMethod `
        -Method Post `
        -Uri $uri `
        -Header $header `
        -ContentType 'application/json' `
        -Body ($body | ConvertTo-Json)
    if ($parsed.errors) {
        # Write GraphQL errors to error pipeline
        foreach ($err in $parsed.errors) {
            # Convert error to Exception
            $exception = [Exception]::new("$($err.message)`nAt $($err.path -join '.')")
            # Copy over metadata
            foreach ($prop in $err.PSObject.Properties) {
                if ($prop.Name -eq 'message') {
                    continue
                }
                Add-Member -InputObject $exception -NotePropertyName ($prop.Name[0].ToString().ToUpper() + $prop.Name.Substring(1)) -NotePropertyValue $prop.Value
            }
            Write-Error -Exception $exception
        }
    }
    $parsed.data
}
Set-Alias Invoke-SrcApiRequest Invoke-SourcegraphApiRequest
