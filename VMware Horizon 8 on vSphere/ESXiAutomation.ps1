function Capture-HostData1 {
  Param(  
        [string]$HostName,
        [string]$TestName)

    Write-Host "$(Get-Date)  Starting performance data capture on hypervisor:" $hostname


    $delay = 30
    $timeout = [math]::Round($Duration + ($delay * 5))
    $path = $LogFilePath + $TestName + "-" + $HostName + ".csv"
    $path
  

    $command = "/bin/esxtop -b -d $delay -n 96 > $path&"
    $command 
    
    $ESXpassword = ConvertTo-SecureString $ESXPassword -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential $ESXUsername, $ESXpassword


    #New-SshSession -ComputerName $HostName -Credential $hostCredential -Force
    $session = New-SSHSession -ComputerName $HostName -Credential $hostCredential -Force
    
    try {
    Invoke-SSHCommand -Index $session.SessionId -Command $command -TimeOut 5
    }catch {
    }
    
    
    Get-SSHSession | Remove-SSHSession | Out-Null
    }




    Function Collect-HostData {
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$LogFilePathWhenCompleted
    )
    Write-Host "$(Get-Date)  Collect  performance data from hypervisor." $HostName
    Write-Host "$(Get-Date)  Testname " $TestName
    Write-Host "$(Get-Date)  LogFilePathWhenCompleted " $LogFilePathWhenCompleted
    
   
   # $testNameFilter = $TestName + "_run"
   # $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}

    $ESXpassword = ConvertTo-SecureString $ESXPassword -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential $ESXUsername, $ESXpassword

#    foreach ($testRun in $testRuns) {       
#        $testRunName = $testRun.Name + ".csv"
        
        
        $remoteFile = $LogFilePath + $TestName + "-" + $HostName + ".csv"
        $localFile = $LogFilePathWhenCompleted + "\" + $TestName + "-" + $HostName + ".csv"
        
        #$remotefile
        #$localfile

		try
		{
			Get-SCPFile -HostName $HostName -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential -Force -OperationTimeout 300 -ConnectionTimeOut 300	
			Write-Host "$(Get-Date)  Cleaning up old perf counters" 
			$session = New-SSHSession -ComputerName $HostName -Credential $hostCredential -Force -ConnectionTimeOut 60
			Invoke-SSHCommand -Index $session.SessionId -Command "rm -rf $remoteFile" -TimeOut 60 
			Get-SSHSession | Remove-SSHSession | Out-Null
		}
		catch
		{
			Write-Host "$(Get-Date)  Could not collect performance information from $hostname : $_"
		
		}
		
        
        
    }
