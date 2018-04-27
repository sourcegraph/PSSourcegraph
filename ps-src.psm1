
function Invoke-SourcegraphApiRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $Endpoint = 'https://sourcegraph.com/.api/graphql',

        [Parameter(Mandatory, Position = 0)]
        [string] $Query,

        $Variables = @{},

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    $header = @{
        "Authorization" = "token $Token"
        "User-Agent"    = "PowerShell ps-src client"
    }
    $body = @{
        query     = $Query
        variables = $Variables
    }
    if ($PSCmdlet.ShouldProcess("Invoke", "Invoke Sourcegraph API request?", "Sourcegraph API request")) {
        $response = Invoke-WebRequest `
            -Method Post `
            -Uri $Endpoint `
            -Header $header `
            -ContentType 'application/json' `
            -Body ($body | ConvertTo-Json)
        $parsed = $response.Content | ConvertFrom-Json
        if ($parsed.errors) {
            foreach ($error in $parsed.errors) {
                Write-Error -Exception $error
            }
        }
        $parsed.data
    }
}
Set-Alias Invoke-SGApiRequest Invoke-SourcegraphApiRequest
