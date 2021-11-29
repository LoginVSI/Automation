$PoolName = "Win11-21H2"
$MachineName = "Win11-*"
$Test_Number_Users = 200
$TestID = "[Your test ID]"
$Comment = "Automated test"
$TestDate = $(get-date -f yyyy-MM-dd-HH-mm)
$Testname = $PoolName+"-"+$TestDate
$LogFilePathWhenCompleted = "C:\LogFiles"
$MinNumberOfLaunchers=20

#Create a directory to create a local copy of ESXtop logfiles
New-Item -Path $LogFilePathWhenCompleted -Name "Logfiles" -ItemType "directory" -ErrorAction SilentlyContinue
Start-Transcript -Path $LogFilePathWhenCompleted"\Logfiles"\$Testname".log"


#Ideally all tests start the same amount of time after resettting all virtual machines
$MaxTestPreparationTime=(get-date).AddMinutes(20)

#ESXi Configuration
$LogFilePath = "/vmfs/volumes/Logs/"
$ESXUserName = "root"
$ESXPassword = "[Password]"


#vSphere configuration
$vSphereServer="[IP]"
$vSphereUsername="[USERNAME]"
$vSpherePassword="[PASSWORD]"

#Horizon Connection Server
$HCServer="[FQDN]"
$HCUsername="[USERNAME]"
$HCPassword="[PASSWORD]"
$HCDomain="[DOMAIN]"

#Load Login enterprise stuff
 . LoginEnterpriseFunctions.ps1 
 . ESXiAutomation.ps1
 
# Loading powercli modules
Import-Module VMware.VimAutomation.HorizonView
Import-Module VMware.VimAutomation.Core

write-host connecting to Horizon Connection Server: $HCServer
$HVServer1 = Connect-HVServer -Server $HCServer -User $HCUsername -Password $HCPassword -Domain $HCDomain
write-host connecting to VMware vSphere: $vSphereServer
$VIServer1 = Connect-VIServer -Server $vSphereServer -User $vSphereUsername -Password $vSpherePassword -Force



#Reboot all launchers
write-host $(Get-Date) "Reboot all launchers"
get-vm -name t1-ls* | restart-VM -Confirm:$False
write-host $(Get-Date) "Waiting for launchers to report ready (Configured: $MinNumberOfLaunchers) "
sleep 30

while ((Get-LeLaunchers).count -ne $MinNumberOfLaunchers) {
         write-host $(Get-Date) "Waiting for launchers to restart(" (Get-LeLaunchers).count ")"
         Start-Sleep -Seconds 10
    }
write-host $(Get-Date) (Get-LeLaunchers).count "Launchers reported ready and online"

#Reboot all VMs in desktop pool
$VMS = get-vm $MachineName
    write-host $(Get-Date) "Reboot all machines in desktop-pool:" $VMS.Count
    foreach ($vm in $VMS){
        try {
        $stopVM=Stop-VM -VM $VM.name -Confirm:$False -RunAsync
        #$VM.Name
        }catch {
        write-host $(Get-Date) $vm.Name -ForegroundColor red
        }
    }DO{
        $PoolAvailable = (get-hvmachinesummary -PoolName $PoolName | where {$_.base.basicstate -eq "AVAILABLE"}).count
        write-host $(Get-Date) "Waiting for pool to restart(" $PoolAvailable ")"
        sleep 30
    }
    Until ( $PoolAvailable -ge $Test_Number_Users)

write-host $(Get-Date) "All machines available, moving on. Test users:  " $Test_Number_Users " Pool size: " $PoolAvailable

#ideally all tests start the same amount of time after resetting all vms in the desktop pool (max 20 minutes)
$MaxTestPreparationTimeLeft=NEW-TIMESPAN –Start (GET-DATE) –End $MaxTestPreparationTime

If ($MaxTestPreparationTimeLeft.Minutes -gt 0)
 { 
     write-host $(Get-Date) "Sleeping for" $MaxTestPreparationTimeLeft.minutes "Minutes until" $MaxTestPreparationTime
     sleep ($MaxTestPreparationTimeLeft.Minutes * 60)
 }else{
    write-host $(Get-Date) "Exeeded maximum test preparation time by " $MaxTestPreparationTimeLeft.Minutes "minutes" -ForegroundColor Red
 }


#Start capturing performance data (ESXtop) 
Capture-HostData1 -HostName "[HOSTNAME]" -TestName $Testname
#Repeat when using multiple hosts

#Connect to Login Enterprise, start test and wait for completion
Start-Test($TestID)
Wait-Test($TestID)

Collect-HostData -Hostname "[HOSTNAME]" -Testname $Testname -LogFilePathWhenCompleted $LogFilePathWhenCompleted"\Logfiles"
#Repeat when using multiple hosts