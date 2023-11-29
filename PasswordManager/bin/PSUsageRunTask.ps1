<#
    .SYNOPSIS
    Cyberark CPM Usage Plugin - Run a Scheduled Task remotely

    .DESCRIPTION
    Run by CyberArk.TPC.exe, passed the action, username, address and logonusername on the command line.  Communicates with TPC via STDIN and STDOUT, accepting
    the credentials via Console::Readline()

    .NOTES
    Requires PSScriptProcess.ini and PSScriptPrompts.ini to work with CyberArk.TPC.exe
	
	The only valid action for a Usage/Service is 'changepass'.   While pmpass and pmnewpass are available, they will always be the same and equal to the new password.

    ExtraParameters should be string with name of Scheduled Task to be run on computer $address

    Note that if passed "sleep:<secs>" with secs > 90, the script will return success because the Cyberark usage will time out otherwise.
    
    .PARAMETER action
    Required by TPC.  For a usage, only valid action is 'changepass'

    .PARAMETER address
    Required by TPC.  Address of server that contains the scheduled task to run

    .PARAMETER username
    required by TPC.  This will be the master object username. Not used by this script

    .PARAMETER logonusername
    required by TPC.  This will be the authentication user to reach out to server. the TPC will provide the logon username if specified, 
    otherwise this will be the master object username.

    .PARAMETER extraparameters
    Provided by the PSScript usage process. For this script, this will contain the name of the scheduled task.  Optionally, the task name can be 
    followed by " sleep:<secs>" which will cause the process to wait that many seconds before running the task.

    .INPUTS
    None.  TPC Plugins use the Console to communicate

    .OUTPUTS
    None.  STDOUT and STDERR are connected to TPC and are used to communicate.

    .EXAMPLE
    bin\PSUsageTestScript.ps1  -taskname 'changepass' -address 'server.domain.local' -username 'admin' -logonusername 'admin'

    .LINK
    
#>
Param(
    [Parameter(Mandatory = $false)][string]$action,
    [Parameter(Mandatory = $true)][string]$address,
    [Parameter(Mandatory = $true)][string]$username,
    [Parameter(Mandatory = $true)][string]$logonUserName,
    [Parameter(Mandatory = $true)][string]$ExtraParameters

)
$ScriptName = "PSUsageRunTask"
# Be sure to set this to a writable directory on the CPM Server
$logdir = "D:\Logs\"

# Logondomain - in an Active Directory environment, this will be the logon domain. Make sure to set this correctly.  Userdomain is the NETBios name.
$logondomain = 'domain.local'
$userdomain = 'DOMAIN'

$CreateLog = $true
$ThisScriptRequiresExtraParameters = $true

$logfile = "$($logdir)$($ScriptName).log"

function isChangeAction {
    Param(
        $action
    )
    if ($action -match 'verifypass|logon|prereconcilepass') {
        return $false
    }
    return $true
}


function New-LogEntry {
    <#
    .SYNOPSIS
    This is all the template script does.  In production, this should probably just return without doing anything
    #>
    Param(
        $msg
    )
    if ($CreateLog) {
        "$(Get-Date) $($msg)" | Out-File -Append -FilePath $logfile
    }
    return
}

function New-UsageLogon {
    <#
        Modify this function if the process requires a logon before manage, for example a REST API.  Template just passes back a PSCredential object that can be used
    #>
    param(
        $address,
        $username,
        $logonPass
    )
    $auth = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $username, ($logonPass | ConvertTo-SecureString -AsPlainText -Force )
    return $auth
}

New-LogEntry "$($ScriptName) Called: $($action) $($address) $($username) $($logonusername)" 

if ($null -eq $action -or $null -eq $address -or $null -eq $username -or $null -eq $logonUserName -or ($null -eq $ExtraParameters -and $ThisScriptRequiresExtraParameters)) {
    Write-Host "Missing arguments. Usage: $($ScriptName).ps1 -action <action> -address <address> -username <username> -logonuser <logonuser> [-extraparameters <extraparameters>]"
    return
}

Write-Host "Enter the logon password:"
$logonpass = [Console]::ReadLine()

if (isChangeAction($action)) {
    Write-Host "Enter the new password:"
    # We don't need the new password, but the process expects us to ask for it
    [Console]::ReadLine() | Out-Null
}
Write-Host "$($action) Input Complete"

$returnMsg = "Script Result: Success"

$sleepsecs = 0
if ($extraparameters -match "(.*) sleep:([0-9]+)") {
    New-LogEntry "Sleeping for $($matches[2]) Seconds"
    $extraparameters = $matches[1]
    $sleepsecs = $matches[2]
}

$taskName = $ExtraParameters
$auth = New-UsageLogon -address $address -username $logonUserName -logonPass $logonpass

if ($null -ne $auth -and $auth.GetType().Name -eq "PSCredential") {
    if ($sleepsecs) {
        if ($sleepsecs -gt 90) {
            # Cyberark usage will time out.  Send back a success message
            Write-host $returnMsg
            Write-Host "Sleeping for $($sleepsecs) Seconds"
        }
        Start-Sleep $sleepsecs
    }
    $out = & c:\Windows\System32\schtasks.exe /Run /S $address /u "$($userdomain)\$($logonusername)" /p "$($logonpass)" /TN "$taskname"
    $rc = $?

    if ($rc -ne $true -or $out -notmatch "SUCCESS") {
        $returnMsg = "Error has occurred: $($out)"
    }
}
else {
    $returnMsg = "Logon Failure $($auth)"
}



New-LogEntry "Returning: $($returnMsg)"
Write-Host $returnMsg