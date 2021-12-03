Write-Host Login Enterprise - Example Automation
#Read configuration file
If ($config -eq $null)
{
    $config = Get-Content -Path "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json
}

$TestDate = $(get-date -f yyyy-MM-dd-HH-mm)
$Testname = $config.VMwareHorizon_PoolName+"-"+$TestDate
Write-host Starting test: $Testname


#Create a directory to create a local copy of ESXtop logfiles

New-Item -ItemType "directory" -Path $config.Automation_LogFilesPathWhenCompleted -ErrorAction SilentlyContinue
$TranscriptLocation = $config.Automation_LogFilesPathWhenCompleted+"\"+$Testname+".log"
write-host Storing local logfiles at: $TranscriptLocation
Start-Transcript -Path $TranscriptLocation


#Ideally all tests start the same amount of time after resettting all virtual machines
$MaxTestPreparationTime=(get-date).AddMinutes($config.LoginEnterprise_MaxTestPreparationTime)

#Load Login enterprise stuff
 . $PSScriptRoot\LoginEnterpriseFunctions.ps1
 . $PSScriptRoot\ESXiAutomation.ps1
 
# Loading powercli modules
Import-Module VMware.VimAutomation.HorizonView
Import-Module VMware.VimAutomation.Core

write-host connecting to Horizon Connection Server: $config.VMwareHorizon_ConnectionServer

$HVServer1 = Connect-HVServer -Server $config.VMwareHorizon_ConnectionServer -User $config.VMwareHorizon_Username -Password $config.VMwareHorizon_Password -Domain $config.VMwareHorizon_Domain
write-host connecting to VMware vSphere: $config.VMwarevSphere_Server
$VIServer1 = Connect-VIServer -Server $config.VMwarevSphere_Server -User $config.VMwarevSphere_Username -Password $config.VMwarevSphere_Password -Force


#Reboot all launchers
write-host $(Get-Date) "Reboot all launchers" $config.LoginEnterprise_Launcher_Names
get-vm -name $config.LoginEnterprise_Launcher_Names | restart-VM -Confirm:$False
write-host $(Get-Date) "Waiting for launchers to reboot (Configured minimum: "$config.LoginEnterprise_MinNumberOfLaunchers ")"
sleep 30

#wait till number of launchers is greater than or equal to minimum
while ($true) {
         write-host $(Get-Date) "Waiting for launchers to complete reboot and report ready (" (Get-LeLaunchers).count")"
         Start-Sleep -Seconds 10
         if ((Get-LeLaunchers).count -ge $config.LoginEnterprise_MinNumberOfLaunchers) {break}
    }
write-host $(Get-Date) (Get-LeLaunchers).count "Launchers reported ready and online"

#Reboot all VMs in desktop pool
$VMS = get-vm $config.VMwareHorizon_PoolVMNamingPattern
    write-host $(Get-Date) "Reboot all machines in desktop-pool:" $VMS.Count
    foreach ($vm in $VMS){
        try {
        $stopVM=Stop-VM -VM $VM.name -Confirm:$False -RunAsync
        #$VM.Name
        }catch {
        write-host $(Get-Date) $vm.Name -ForegroundColor red
        }
    }DO{
        $PoolAvailable = (get-hvmachinesummary -PoolName $config.VMwareHorizon_PoolName | where {$_.base.basicstate -eq "AVAILABLE"}).count
        write-host $(Get-Date) "Waiting for pool to restart(" $PoolAvailable ")"
        sleep 30
    }
    Until ( $PoolAvailable -ge $config.LoginEnterprise_TestNumberOfUsers)

write-host $(Get-Date) "All machines available, moving on. Test users:  " $config.LoginEnterprise_TestNumberOfUsers " Pool size: " $PoolAvailable

#ideally all tests start the same amount of time after resetting all vms in the desktop pool (max 20 minutes)
$MaxTestPreparationTimeLeft=NEW-TIMESPAN –Start (GET-DATE) –End $config.LoginEnterprise_MaxTestPreparationTime

If ($MaxTestPreparationTimeLeft.Minutes -gt 0)
 { 
     write-host $(Get-Date) "Sleeping for" $MaxTestPreparationTimeLeft.minutes "Minutes until" $config.LoginEnterprise_MaxTestPreparationTime
     sleep ($MaxTestPreparationTimeLeft.Minutes * 60)
 }else{
    write-host $(Get-Date) "Exeeded maximum test preparation time by " $MaxTestPreparationTimeLeft.Minutes "minutes" -ForegroundColor Red
 }


#Start capturing performance data (ESXtop) 
Capture-HostData1 -HostName $config.VMwareESXi_Hosts -TestName $Testname


#Connect to Login Enterprise, start test and wait for completion
Start-Test($config.LoginEnterprise_TestID)
Wait-Test($config.LoginEnterprise_TestID)

Collect-HostData -Hostname $config.VMwareESXi_Hosts -Testname $Testname -LogFilePathWhenCompleted $config.Automation_LogFilesPathWhenCompleted"\"


