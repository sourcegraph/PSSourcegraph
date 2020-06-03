Import-Module -Scope Local "$PSScriptRoot/api.psm1"

$CreateUserQuery = Get-Content -Raw "$PSScriptRoot/../queries/CreateUser.graphql"
function New-User {
    <#
    .SYNOPSIS
        Creates a new user account
    .DESCRIPTION
        Creates a new user account
    .PARAMETER Username
        The username for the new user
    .PARAMETER Email
        The email address of the new user
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Username,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string] $Email,

        [Uri] $Endpoint = 'https://sourcegraph.com',
        [SecureString] $Token
    )

    if ($PSCmdlet.ShouldProcess("Creating user $Username <$Email>", "Create user $Username <$Email>?", "Confirm")) {
        $data = Invoke-ApiRequest -Query $CreateUserQuery -Variables @{username = $Username; email = $Email} -Endpoint $Endpoint -Token $Token
        $data.createUser
    }
}
Export-ModuleMember -Function New-User

$UserFields = Get-Content -Raw "$PSScriptRoot/../queries/UserFields.graphql"
$UserQuery = (Get-Content -Raw "$PSScriptRoot/../queries/User.graphql") + $UserFields
$UsersQuery = (Get-Content -Raw "$PSScriptRoot/../queries/Users.graphql") + $UserFields
function Get-User {
    <#
    .SYNOPSIS
        Get users on a Sourcegraph instance
    .PARAMETER Username
        Get only the user with the given username
    .PARAMETER Endpoint
        The endpoint URL of the Sourcegraph instance (default https://sourcegraph.com)
    .PARAMETER Token
        The authentication token (if needed). Go to the settings page on Sourcegraph to generate one.
    #>
    [CmdletBinding(SupportsPaging)]
    param(
        [Uri] $Endpoint = 'https://sourcegraph.com',
        [string] $Username,
        [string] $Query,
        [string] $Tag,

        [ValidateSet('TODAY', 'THIS_WEEK', 'THIS_MONTH', 'ALL_TIME')]
        [string] $ActivePeriod,

        [SecureString] $Token
    )

    if ($Username) {
        $query = $UserQuery
        $variables = @{ username = $Username }
        (Invoke-ApiRequest -Query $UserQuery -Variables $variables -Endpoint $Endpoint -Token $Token).user
    } else {
        $variables = @{ query = $Query; tag = $Tag; activePeriod = $ActivePeriod }
        if ($PSBoundParameters.ContainsKey('First')) {
            $variables['first'] = $PSCmdlet.PagingParameters.First
        }
        $data = Invoke-ApiRequest -Query $UsersQuery -Variables $variables -Endpoint $Endpoint -Token $Token
        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            $PSCmdlet.PagingParameters.NewTotalCount($data.users.totalCount, 1)
        }
        $data.users.nodes
    }
}
Export-ModuleMember -Function Get-User
