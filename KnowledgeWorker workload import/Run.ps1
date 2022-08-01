# Connections details
$ApplianceURL = ""
$ApplianceToken = ""
if ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
# Define the applicationgroups and applications that you want to to create in LE here.
$ApplicationGroups = @(
    @{
        "Name"        = "KnowledgeWorker"
        "Description" = "KnowledgeWorker Application Group"
        Applications  = @(
            @{
                Name         = "KW_PrepOffice2019"
                commandLine  = "WINWORD.EXE"
                description  = "KW Word"
                scriptPath   = "$ScriptRoot\KW_Word_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $true
                leaveRunning = $false
            },
            @{
                Name         = "KW_Outlook"
                commandLine  = "outlook.exe /importprf %TEMP%\LoginPI\outlook.prf"
                description  = "KW Outlook"
                scriptPath   = "$ScriptRoot\KW_Outlook_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $true
            },
            @{
                name         = "KW_Edge"
                url          = "https://www.microsoft.com"
                description  = "Microsoft Edge"
                scriptPath   = "$ScriptRoot\KW_Edge_Default_Script.cs"
                type         = "WebApp"
                browserName  = "edgeChromium"
                runOnce      = $false
                #leaveRunning is not supported on WebApps, set it to false
                leaveRunning = $false
            },
            @{
                name         = "KW_Excel"
                commandLine  = "EXCEL.EXE"
                description  = "Microsoft Excel"
                scriptPath   = "$ScriptRoot\KW_Excel_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $true
            },
            @{
                name         = "KW_PowerPoint"
                commandLine  = "POWERPNT.EXE"
                description  = "Microsoft PowerPoint"
                scriptPath   = "$ScriptRoot\KW_PowerPoint_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $true
            },
            @{
                Name         = "KW_Word"
                commandLine  = "WINWORD.EXE"
                description  = "KW Word"
                scriptPath   = "$ScriptRoot\KW_word_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $true
            },
            @{
                name         = "Close KW_Excel"
                commandLine  = "EXCEL.EXE"
                description  = "Microsoft Excel"
                scriptPath   = "$ScriptRoot\KW_Close_Excel_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $false
            },
            @{
                name         = "Close KW_PowerPoint"
                commandLine  = "POWERPNT.EXE"
                description  = "Microsoft PowerPoint"
                scriptPath   = "$ScriptRoot\KW_Close_PowerPoint_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $false
            },
            @{
                name         = "Close KW_Word"
                commandLine  = "WINWORD.EXE"
                description  = "Microsoft Word"
                scriptPath   = "$ScriptRoot\KW_Close_Word_Default_Script.cs"
                type         = "WindowsApp"
                runOnce      = $false
                leaveRunning = $false
            }
        )
    }
)

if ($PSEdition -ne "Desktop") {
    throw "This script is only supported on Windows PowerShell"
}

if (-not("SSLValidator" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(SSLValidator.ReturnTrue);
    }
}
"@
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()



$Header = @{
    "Authorization" = "Bearer $ApplianceToken"
}

$Body = @{
    orderBy   = "name"
    direction = "asc"
    count     = 999
    include   = "none"
}
$ExistingApps = Invoke-RestMethod -Method GET -Headers $Header -uri "$ApplianceURL/publicApi/v5/applications" -Body $body 
$ExistingAppGroups = Invoke-RestMethod -Method GET -Headers $Header -uri "$ApplianceURL/publicApi/v5/application-groups" -Body $body
$Steps = @()

foreach ($ApplicationGroup in $ApplicationGroups) {
    # Create the applications if they don't exist and upload their scripts
    foreach ($application in $ApplicationGroup.applications) {
        $ExistingApp = $null
        $ExistingApp = $ExistingApps.Items | Where-Object { $_.Name -eq $application.Name }
        if ($null -eq $ExistingApp) {
            Write-Host "Creating app $($Application.Name)"
            if ($application.type -eq "WindowsApp") {
                $Body = @{
                    type        = $application.type
                    commandline = $application.commandLine
                    #id          = New-Guid
                    name        = $application.name
                    description = $application.description
                } | ConvertTo-Json
            } else {
                $Body = @{
                    type        = $application.type
                    url         = $application.url
                    name        = $application.name
                    browserName = $application.browserName
                    description = $application.description
                } | ConvertTo-Json
            }

            $result = Invoke-RestMethod -Method "POST" -uri "$ApplianceUrl/publicApi/v5/applications" -Body $Body -Headers $Header -ContentType "application/json"
            $appId = $result.id
        } else {
            write-host "Application $($application.name) already exists, skipping creation"
            $appId = $ExistingApp.Id
        }
        # Upload the script
        Write-Host "Uploading script for $($application.name)"
        $Body = Get-Content $application.scriptPath -Raw
        $ScriptId = Invoke-RestMethod -Method POST -Uri "$ApplianceUrl/publicApi/v5/applications/$appId/script" -Headers $Header -Body $Body -ContentType "application/json"
        # Add  the app to applicationgroup
        $Steps += @{
            type          = "AppInvocation"
            applicationId = $appId
            runOnce       = $application.runOnce
            leaveRunning  = $application.leaveRunning
            isEnabled     = $true
        }
    }
    $ExistingAppGroup = $null
    $ExistingAppGroup = $ExistingAppGroups.items | Where-Object { $_.name -eq $ApplicationGroup.Name }
    # Create the application group if it doesn't exist
    if ($null -eq $ExistingAppGroup) {
        Write-Host "Processing app group $($ApplicationGroup.Name)"

        $Body = @{
            name        = $ApplicationGroup.Name
            description = $ApplicationGroup.Description
            steps       = $steps
        } | ConvertTo-Json
        $ApplicationGroupId = Invoke-RestMethod -Method "POST" -Uri "$ApplianceURL/publicApi/v5/application-groups" -Body $Body -Headers $Header -ContentType "application/json"
    } else { Write-Host "ApplicationGroup $($applicationGroup.Name) already exists, skipping creation..." }
}
