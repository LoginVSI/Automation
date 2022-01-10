$password = Read-Host -AsSecureString "Enter password"


$nrOfUsers = "500"
$fqdn = "LoginEnterprise.yourorganization.com"
$token = 'your_configuration_token' 
$naming = "LE-TestUser-"
$domainID = "yourorganization.com"
$UPN = "@yourorganization.com"
$adPath = "OU=TestUsers,DC=your,DC=domain"

function New-LeUser {
    Param (
        [string]$username,
        [string]$domainID,
        [string]$password
    )

    # this is only required for older version of PowerShell/.NET
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # WARNING: ignoring SSL/TLS certificate errors is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true; }
    
    $user = @{
        username = $username
        domainID = $domainID
        password = $password
    } | ConvertTo-Json

    $header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $token"
    }

    $params = @{
        Uri         = 'https://' + $fqdn + '/publicApi/v4/accounts'
        Headers     = $header
        Method      = 'POST'
        Body        = $user
        ContentType = 'application/json'
    }

    $Response = Invoke-RestMethod @params
    $Response.id
}

function Get-Usernames {
    Param (
        [Parameter(Mandatory = $true)]
        [int]$Start,
        [Parameter(Mandatory = $true)]
        [string]$End
    )
 
    $Start..$End | % {
        $Number = ($Start++).ToString(("0").PadLeft($End.Length,'0'))
        $Name = $naming + $Number
        [array]$Counts += $Name }
    Return $Counts
}

foreach ($User in (Get-Usernames 1 $nrOfUsers)) {
    $UPN = ""
    $UPN = $User + $UPN 
    New-LeUser -username $User -domainID $domainID -password ([Net.NetworkCredential]::new('', $password).Password) 
    New-ADUser -Name "$User" -SamAccountName "$User" -UserPrincipalName "$UPN" -Path $global:adPath -AccountPassword $Password -Enabled $true -PasswordNeverExpires $true																									
} 
  
