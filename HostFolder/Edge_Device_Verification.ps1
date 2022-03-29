$FQDN = "pbiwvdle.eastus.cloudapp.azure.com"
$TestName = "Laptops"


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Set variables and start logging
$TempFolder = Join-Path $Env:TEMP "LoginEnterprise"

$LeRemoteFile = "https://" + $FQDN + "/contentDelivery/api/logonApp/unsecured"

# Create necessary folders and cleanup existing folders if present
if(!([System.IO.Directory]::Exists($TempFolder)))
{
  New-Item -ItemType Directory -Force $TempFolder
}

$LeFolder = (Get-Item -Path $TempFolder).FullName
$LeZip = Join-Path $LeFolder "Logon.zip"
$LogonFile = Join-Path $LeFolder "LoginPi.Logon.exe"

if([System.IO.Directory]::Exists($LeFolder))
{
    Remove-Item -Recurse -Force $LeFolder
}
New-Item -ItemType Directory -Force $LeFolder

if([System.IO.File]::Exists($LeZip))
{
    Remove-Item -Recurse -Force $LeZip
}

# Download, unzip and start engine
$attemptsCount = 0
$maxAttemptsCount = 30
$succeeded = $false
$retryInterval = 2 #seconds

echo "Downloading Logon Executable from '$LeRemoteFile'..."
while (!$succeeded)
{
    try 
    {
        $attemptsCount++

        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($LeRemoteFile, $LeZip)
        (new-object -com shell.application).namespace($LeFolder).CopyHere((new-object -com shell.application).namespace($LeZip).Items(), 0x14);
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

        $succeeded = $true
        echo "Engine started succesfully"
    }
    catch
    {
        if ($attemptsCount -lt $maxAttemptsCount)
        {
            echo "Attempt $attemptsCount failed. Reason: $_"
            echo "Waiting for $retryInterval seconds and will try again"
            start-sleep -seconds $retryInterval
        }
        else
        {
            echo "All attempts failed. Logging off"
            shutdown -l -f
            break
        }
    }
}



& $LogonFile "https://$FQDN" "$TestName"
Return 0

