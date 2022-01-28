$applianceA = @{fqdn = 'fqdn1_appliance1';token = 'fqdn1_token1' }
$applianceB = @{fqdn = 'fqdn2_appliance2';token = 'fqdn2_token2' }

##############################################################################################################
$code = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
Add-Type -TypeDefinition $code

function Get-LeApplications {
    Param (
        [Parameter(Mandatory)] [ValidateSet('name', 'description')] [string] $orderBy,
        [Parameter(Mandatory)] [ValidateSet('ascending', 'descending')] [string] $direction,
        [Parameter(Mandatory)] [int]$count,
        [ValidateSet('none', 'script', 'timers', 'all')] $include,
        [ValidateSet($true, $false)] $includeTotalCount,
        [ValidateSet('environment', 'workload', 'thresholds', 'all')] $offset,
        [Parameter(Mandatory)][string] $fqdn,
        [Parameter(Mandatory)][string] $token
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Body = @{
        orderBy   = "Name"
        direction = "Ascending"
        count     = "5000"
    }
    
    if($null -ne $include){ $Body += @{
        include = "$include"
        }
    }

    if($null -ne $includeTotalCount){ $Body += @{
        includeTotalCount = "$includeTotalCount"
        }
    }
    
    if($null -ne $offset){ $Body += @{
        offset = "$offset"
        }
    }   

    $Parameters = @{
        Uri         = 'https://' + $fqdn + '/publicApi/v4/applications'
        Headers     = $Header
        Method      = 'GET'
        body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response.items
}

function Get-LeApplication {
    Param (
        [Parameter(Mandatory)][string] $applicationId,
        [ValidateSet('none', 'script', 'timers', 'all')] $include,
        [Parameter(Mandatory)][string]$fqdn,
        [Parameter(Mandatory)][string]$token
    )
    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Body = @{
    }
    
    if($null -ne $include){ $Body += @{
        include = "$include"
        }
    }

    $Parameters = @{
        Uri         = 'https://' + $fqdn + '/publicApi/v4/applications/' + $applicationId
        Headers     = $Header
        Method      = 'GET'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response 
}

function New-LeApplication {
    Param (
        $commandline,
        $name,
        $description,
        $jsonFile,
        [Parameter(Mandatory)][string]$fqdn,
        [Parameter(Mandatory)][string]$token
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    if($null -ne $jsonFile){
        $Body = $jsonFile | ConvertTo-Json
    }Else{
        $Body = @{
        '$type'     = "WindowsApp"
        commandline = $commandline
        id          = New-Guid
        name        = $name
        description = $description
        } | ConvertTo-Json
    }

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Parameters = @{
        Uri         = 'https://' + $fqdn + '/publicApi/v4/applications'
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

function New-Script {
    Param (
        [Parameter(Mandatory)][string]$fqdn,
        [Parameter(Mandatory)][string]$token,
        $applicationId,
        $json
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

    $Body = $json

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $Parameters = @{
        Uri         = 'https://' + $fqdn + '/publicApi/v4/applications/' + $applicationId + '/script'
        Headers     = $header
        Method      = 'POST'
        Body        = $Body
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @Parameters
    $Response
}

$selection = Get-LeApplications -orderBy name -direction ascending -include all -count 1000 -fqdn $applianceA.fqdn -token $applianceA.token | Select-Object name,description,id,commandline | Out-GridView -OutputMode Multiple

foreach ($app in $selection){
    
    $oldApp = Get-LeApplication -applicationId $app.id -include all -fqdn $ApplianceA.fqdn -token $applianceA.token
    $newApp = New-LeApplication -jsonFile $oldApp -fqdn $ApplianceB.fqdn -token $applianceB.token
    New-Script -fqdn $applianceB.fqdn -token $applianceB.token -applicationId $newApp.id -json $oldApp.script

}


