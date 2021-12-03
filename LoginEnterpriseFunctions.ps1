$global:fqdn = "your_fqdn"
$global:token = 'your_configuration_token' 

$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code

#Login Enterprise Functions 
#Accounts--------------------------------
function New-LeAccount {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$domainID,
        [Parameter(Mandatory = $true)]
        [string]$password
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    $Body = @{
        username = $username
        domainID = $domainID
        password = $password
    } | ConvertTo-Json

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/accounts'
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Get-LeAccounts {
    Param (
        [string]$orderBy = "Username",
        [string]$Direction = "Ascending",
        [string]$Count = "50",
        [string]$Include = "none"
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/Accounts'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Set-LeAccountStatus {
    Param (
        [string]$id,
        [switch]$disable
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    if ($disable.IsPresent) {
        $status = $false
    }
    else {
        $status = $true
    }

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = $status | ConvertTo-Json

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/Accounts/' + $id + '/enabled'
        Headers     = $Header
        Method      = 'PUT'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Remove-LeAccounts {
    Param (
        [Parameter(Mandatory = $true)]
        $ids
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    $Body = ConvertTo-Json @($ids) 

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/accounts'
        Headers     = $header
        Method      = 'DELETE'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

#AccountGroups----------------------------
function Get-LeAccountGroups {
    Param (
        [string]$orderBy = "Name",
        [string]$Direction = "Ascending",
        [string]$Count = "50",
        [string]$Include = "none"
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeAccountGroup {
    [CmdletBinding(DefaultParametersetName = 'None')] 
    Param (
        [Parameter(Position = 0, Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,      
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [string]$Description,
        [Array]$MemberIds

    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    if ($Filter -eq $false) {
        $AccountGroup = @{
            '$type'     = "Selection"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            memberIds   = $MemberIds
        } | ConvertTo-Json
    }
    else {
        $AccountGroup = @{
            '$type'     = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups'
        Headers     = $header
        Method      = 'POST'
        Body        = $AccountGroup
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Get-LeAccountGroupMembers {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [string]$orderBy = "Username",
        [string]$Direction = "Ascending",
        [string]$Count = "50"
    )


    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        groupID   = $GroupId
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups/' + $GroupId + '/Members'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeAccountGroupMember {
    Param (
        [string]$GroupId,
        [array]$ids
    )


    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()


    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = ConvertTo-Json @($ids) 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups/' + $GroupId + '/members'
        Headers     = $Header
        Method      = 'PUT'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Remove-LeAccountGroups {
    Param (
        [Parameter(Mandatory = $true)]
        $ids
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    $Body = ConvertTo-Json @($ids) 

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/account-groups'
        Headers     = $header
        Method      = 'DELETE'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

#Launchers--------------------------------
function Get-LeLauncherGroups {
    Param (
        [string]$orderBy = "Name",
        [string]$Direction = "Ascending",
        [string]$Count = "50",
        [string]$Include = "none"
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/launcher-groups'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeLauncherGroup {
    [CmdletBinding(DefaultParametersetName = 'None')] 
    Param (
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,      
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [array]$LauncherNames,
        [string]$Description
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()


    if ($Filter.IsPresent) {
        $Body = @{
            '$type'     = "Filter"
            groupId     = New-Guid
            name        = $Name
            description = $Description
            condition   = $Condition
        } | ConvertTo-Json
    }
    else {
        $Body = @{
            '$type'       = "Selection"
            groupId       = New-Guid
            name          = $Name
            description   = $Description
            launcherNames = $LauncherNames
        } | ConvertTo-Json
    }


    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/launcher-groups'
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Get-LeLauncherGroupMembers {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [string]$orderBy = "Name",
        [string]$Direction = "Ascending",
        [string]$Count = "50",
        [string]$Include = "none"
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        groupID   = $GroupId
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/launcher-groups/' + $GroupId + '/members'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Remove-LeLauncherGroups {
    Param (
        [Parameter(Mandatory = $true)]
        $ids
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    $Body = ConvertTo-Json @($ids) 

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/launcher-groups'
        Headers     = $header
        Method      = 'DELETE'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Get-LeLaunchers {
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
 
    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
 
    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }
 
    $Body = @{
        orderBy   = "Name"
        direction = "Ascending"
        count     = "5000"
    } 
 
    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/launchers'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }
 
    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

#Applications-----------------------------
function Get-LeApplications {
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        orderBy   = "Name"
        direction = "Ascending"
        count     = "5000"
        include   = "none" 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/applications'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function New-LeApplication {
    Param (
        [string]$commandline,
        [string]$name,
        [string]$description
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Body = @{
        '$type'     = "WindowsApp"
        commandline = $commandline
        id          = New-Guid
        name        = $name
        description = $description
    } | ConvertTo-Json

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = $global:url
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

function Remove-LeApplications {
    Param (
        [Parameter(Mandatory = $true)]
        $ids
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    $Body = ConvertTo-Json @($ids) 

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/applications'
        Headers     = $header
        Method      = 'DELETE'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

#Tests-----------------------------
function Get-Tests {
    Param (
        [Parameter(Mandatory)] [ValidateSet('name', 'connector', 'description')] [string] $orderBy,
        [Parameter(Mandatory)] [ValidateSet('continuousTest', 'loadTest', 'applicationTest')] [string] $testType,
        [Parameter(Mandatory)] [ValidateSet('ascending', 'descending')] [string] $direction,
        [Parameter(Mandatory)] [ValidateSet('environment', 'workload', 'thresholds', 'all')] [string] $include,
        [Parameter(Mandatory)] [string]$count
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        testType  = $testType
        orderBy   = $orderBy
        direction = $direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Get-Test {
    Param (
        [Parameter(Mandatory)] [string] $testId,
        [Parameter(Mandatory)] [ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')] [string] $include
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        include = $include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $testId
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

function Copy-Test {
    Param (
        $Test    
    )
 
    $Type = $test.'$type'
    $Name = "Copy of " + $test.name
    $Description = "Copy of " + $test.description
    $ConnectorID = $test.environment.connectorConfiguration.connector.id
    $connectorParameterValues = $test.environment.connectorConfiguration.connectorParameterValues
    [array]$AccountGroups = $test.environment.accountGroups.groupId
    [array]$LauncherGroups = $test.environment.launcherGroups.id
    $Workload = $test.workload 

    $connectorParameters = $null
    foreach ($value in $connectorParameterValues) {
        $connectorParameters += [pscustomobject]@{Key = $value.value; Value = $value.key; }
        $connectorParameters = @($connectorParameters)
    }
    $connectorParameterValues = $connectorParameters

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    
    $Body = [ordered]@{
        '$type'                  = "$Type"
        Name                     = $Name
        Description              = $Description
        ConnectorID              = $ConnectorID
        ConnectorParameterValues = $connectorParameterValues
        AccountGroups            = $AccountGroups
        LauncherGroups           = $LauncherGroups
        Workload                 = $Workload
    } | ConvertTo-Json
 
    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $params = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests'
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response.id
}

function Update-Test {
    Param (
        $Oldtest,
        $Newtest    
    )
 
    $Type = $Oldtest.'$type'
    $Name = $Newtest.name
    $Description = $Newtest.description
    $ConnectorID = $Oldtest.environment.connectorConfiguration.connector.id
    $connectorParameterValues = $Oldtest.environment.connectorConfiguration.connectorParameterValues
    
    [array]$AccountGroups = $Oldtest.environment.accountGroups.groupId
    [array]$LauncherGroups = $Oldtest.environment.launcherGroups.id

    $connectorParameters = $null
    foreach ($value in $connectorParameterValues) {
        $connectorParameters += [pscustomobject]@{Key = $value.value; Value = $value.key; }
        $connectorParameters = @($connectorParameters)
    }
    $connectorParameterValues = $connectorParameters

    $steps = $null 
    Foreach ($item in $Oldtest.workload.steps) {
        if ($item.'$type' -eq "AppInvocation") { 
            $steps += [pscustomobject]@{'$type' = $item.'$type'; ApplicationId = $item.Application.id; IsEnabled = $item.isEnabled; }
        }
        if ($item.'$type' -eq "Delay") {
            $steps += [pscustomobject]@{'$type' = $item.'$type'; delayInSeconds = $item.delayInSeconds; IsEnabled = $item.isEnabled; }
        }
        $steps = @($steps)
    }

    
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    

    if ($Type -eq "ApplicationTest") {

        if ($null -ne ($Oldtest.Thresholds)) {        
            Foreach ($Threshold in $Oldtest.Thresholds) {
                Update-Threshold -TestId $Newtest.id -Threshold $Threshold
            }
        }

        if ($null -ne ($Oldtest.alertConfigurations.threshold)) {        
            Foreach ($Threshold in $Oldtest.alertConfigurations.threshold) {
                Update-Threshold -TestId $Newtest.id -Threshold $Threshold
            }
        }

        if ($null -eq $Oldtest.emailRecipient) { $Oldtest.emailRecipient = "noreply@test.com" }
        $Body = [ordered]@{
            '$type'                       = "$Type"
            isEmailEnabled                = $Oldtest.isEmailEnabled
            emailRecipient                = $Oldtest.emailRecipient
            includeSuccessfulApplications = $Oldtest.includeSuccessfulApplications
            state                         = $Oldtest.state
            name                          = $Name
            description                   = $Oldtest.description
            ConnectorID                   = $ConnectorID
            ConnectorParameterValues      = $connectorParameterValues
            AccountGroups                 = $AccountGroups
            LauncherGroups                = $LauncherGroups
            steps                         = $steps
        } | ConvertTo-Json
    }

    if ($Type -eq "LoadTest") {
        $Body = [ordered]@{
            '$type'                  = "$Type"
            numberOfSessions         = $Oldtest.numberOfSessions
            rampUpDurationInMinutes  = $Oldtest.rampUpDurationInMinutes
            testDurationInMinutes    = $Oldtest.testDurationInMinutes
            name                     = $Name
            description              = $Oldtest.description
            ConnectorID              = $ConnectorID
            ConnectorParameterValues = $connectorParameterValues
            AccountGroups            = $AccountGroups
            LauncherGroups           = $LauncherGroups
            steps                    = $steps
        } | ConvertTo-Json
    }

    if ($Type -eq "ContinuousTest") {
        $Body = [ordered]@{
            '$type'                  = "$Type"
            scheduleType             = $Oldtest.scheduleType
            intervalInMinutes        = $Oldtest.scheduleIntervalInMinutes
            numberOfSessions         = $Oldtest.numberOfSessions
            takeScriptScreenshots    = $Oldtest.takeScriptScreenshots
            repeatCount              = $Oldtest.repeatCount
            isRepeatEnabled          = $Oldtest.isRepeatEnabled
            isEnabled                = $Oldtest.isEnabled
            restartOnComplete        = $Oldtest.restartOnComplete
            name                     = $Name
            description              = "description"
            connectorID              = $ConnectorID
            connectorParameterValues = $connectorParameterValues
            accountGroups            = $AccountGroups
            launcherGroups           = $LauncherGroups
            steps                    = $steps
        } | ConvertTo-Json
    }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $params = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $Newtest.id
        Headers     = $header
        Method      = 'PUT'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response.id
}

function Update-Threshold {
    Param (
        $TestId,
        $Threshold,
        $NewThreshold          
    )
 
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
 
 
    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }   
    
    if ($Threshold.'$type' -eq "AppThreshold") {
        $Body = [ordered]@{
            applicationId = $Threshold.applicationId
            timer         = $Threshold.timer
            isEnabled     = $Threshold.isEnabled
            value         = $Threshold.value
        } | ConvertTo-Json

        $params = @{
            Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $TestId + '/thresholds'
            Headers     = $header
            Method      = 'POST'
            Body        = $Body
            ContentType = 'application/json'
        }

    }

    if ($Threshold.'$type' -eq "SessionThreshold") {
        
        $NewThreshold = (Get-Tests | Where-Object { $_.id -eq $NewTestId }).thresholds | Where-Object { $_.type -eq $Threshold.type }
                      
        $Body = [ordered]@{
            isEnabled = $Threshold.isEnabled
            value     = $Threshold.value
        } | ConvertTo-Json

        $params = @{
            Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $TestId + '/thresholds/' + $NewThreshold.id
            Headers     = $header
            Method      = 'PUT'
            Body        = $Body
            ContentType = 'application/json'
        }

    }

    $Response = Invoke-RestMethod @params
    $Response.id
}

#TestRuns------------------------------

function Get-TestRuns {
    Param (
        [Parameter(Mandatory)] [string] $testId,
        [Parameter(Mandatory)] [ValidateSet('ascending', 'descending')] [string] $direction,
        [Parameter(Mandatory)] [string]$count,
        [Parameter()] [ValidateSet('none', 'properties', 'all')] [string] $include
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        direction = $direction
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $testId + '/test-runs'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Stop-TestRun {
    Param (
        $testRunId    
    )
 

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    
    $Body = [ordered]@{
        event = "InternalError"
    } | ConvertTo-Json
 
    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $params = @{
        Uri         = 'https://' + $global:fqdn + '/loadTests/test-run/' + $testRunId
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response
}

#Measurements----------------------------

function Get-Measurements {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [Parameter(Mandatory)] [string] $from,
        [Parameter(Mandatory)] [string] $to,
        [Parameter(Mandatory)] [ValidateSet('ascending', 'descending')] [string] $direction,
        [Parameter(Mandatory)] [string]$count,
        [Parameter()] [ValidateSet('sessionMeasurements', 'applicationMeasurements', 'all')] [string] $include
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $Body = @{
        direction = $direction
        from      = $from
        to        = $to
        count     = $Count
        include   = $Include 
    } 

    $Parameters = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/test-runs/' + $testRunId + '/measurements'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items 
}

function Start-Test {
    Param (
        $testId,
        $comment    
    )
 

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    
    $Body = [ordered]@{
        comment = $comment
    } | ConvertTo-Json
 
    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:token"
    }

    $params = @{
        Uri         = 'https://' + $global:fqdn + '/publicApi/v4/tests/' + $testId + '/start'
        Headers     = $header
        Method      = 'PUT'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response
}

function Wait-Test {
    Param (
        [Parameter(Mandatory)] [string] $testId
    )
    
    Write-Host "Waiting for test to complete" -ForegroundColor Green
    while (((Get-Test -testId $testid -include "none").state -eq "running") -or ((Get-Test -testId $testid -include "none").state -eq "stopping")) {
        Write-Host '.' -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "test finished" -ForegroundColor Green
}