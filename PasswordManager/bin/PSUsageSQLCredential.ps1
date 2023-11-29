<#
    .SYNOPSIS
    Cyberark CPM Usage - Update a SQL Credential

    .DESCRIPTION
    Run by CyberArk.TPC.exe, passed the action, username, address and logonusername on the command line.  Communicates with TPC via STDIN and STDOUT, accepting
    the credentials via Console::Readline()

    Update a SQL Credential using the ALTER CREDENTIAL SQL Command. Requires the Logon account to have ALTER ANY CREDENTIAL and CONTROL SERVER SQL Permissions.

    .PARAMETER action
    Standard TPC action - 'changepass'

    .PARAMETER address
    FQDN hostname of the server where the credential lives

    .PARAMETER username
    master username for this usage

    .PARAMETER logonUserName
    Account with local admin privileges for logon to server to make the change

    .PARAMETER ExtraParameters
    instance for the credential\Name of credential
    e.g. master\Report Credential

    .NOTES
    Requires PSScriptProcess.ini and PSScriptPrompts.ini to work with CyberArk.TPC.exe
	
	The only valid action for a Usage/Service is 'changepass'.   While pmpass and pmnewpass are available, they will always be the same and equal to the new password.
    
    .INPUTS
    None.  TPC Plugins use the Console to communicate na pass in the credentials

    .OUTPUTS
    None.  STDOUT and STDERR are connected to TPC and are used to communicate.

    .EXAMPLE
    bin\PSUsageSQLCredential.ps1  -action 'changepass' -address 'dbserver.domain.local' -username 'svcacct1' -logonusername 'adminacct1' -ExtraParameters "master\Report Credential"

    .LINK
    
#>
Param(
    [Parameter(Mandatory = $false)][string]$action,
    [Parameter(Mandatory = $true)][string]$address,
    [Parameter(Mandatory = $true)][string]$username,
    [Parameter(Mandatory = $true)][string]$logonUserName,
    [Parameter(Mandatory = $true)][string]$ExtraParameters

)

$ScriptName = "PSUsageSQLCredential"
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
    Modified for this script: Issues a Remote PS Session command and returns the Session
    #>
    param(
        $address,
        $PSLogon
    )
    
    $RemoteSession = New-PSSession -ComputerName $address -Credential $PSLogon
    return $RemoteSession
}

function Update-Credential {
    Param(
        [Parameter(Mandatory=$true)]$RemoteSession,
        [Parameter(Mandatory=$true)]$address,
        [Parameter(Mandatory=$true)]$dbname,
        [Parameter(Mandatory=$true)]$credentialName,
        [Parameter(Mandatory=$true)]$username,
        [Parameter(Mandatory=$true)]$newPass
    )
    $returnMsg = "Script Result: Success"
    ###
    $sql1 = "use [$($dbname)]"
	$sql2 = "ALTER CREDENTIAL [$($credentialName)] WITH IDENTITY = N'$($username)', SECRET = N'$($newPass)'"
	$scriptstring = "Invoke-SQLCmd -query `"$($sql1)`" -ServerInstance $($address)
	Invoke-SQLCmd -query `"$($sql2)`" -ServerInstance $($address)
	"
    $scriptblock = [Scriptblock]::Create($scriptstring)
	New-LogEntry -msg (($scriptblock | Out-String) -Replace "SECRET = N'.*'","SECRET = N'<pass>'")
    try {
        $ret = Invoke-Command -Session $RemoteSession -Scriptblock $scriptblock -ErrorAction Stop
    }
    catch {
        New-LogEntry -msg "Error on Invoke-Command: $($Error[0] | Out-String )"
        throw $($Error[0])
    }
    if ($ret) {
        $returnMsg = $ret
    }
    return $returnMsg
}

New-LogEntry "$($ScriptName) Called: $($action) $($address) $($username) $($logonUserName) $($Extraparameters)" 

if ($null -eq $action -or $null -eq $address -or $null -eq $username -or $null -eq $logonUserName -or ($null -eq $ExtraParameters -and $ThisScriptRequiresExtraParameters)) {
    Write-Host "Missing arguments. Usage: $($ScriptName).ps1 -action <action> -address <address> -username <username> -logonuser <logonuser> [-extraparameters <extraparameters>]"
    return
}

Write-Host "Enter the logon password:"
$logonpass = [Console]::ReadLine()

if (isChangeAction($action)) {
    Write-Host "Enter the new password:"
    $newPass = [Console]::ReadLine()
}
Write-Host "$($action) Input Complete"

$returnMsg = "Script Result: Success"

if ($extraparameters -match "(.*)\\(.*)") {
    New-LogEntry "Updating Credential for $($extraparameters)"
    $dbname = $matches[1]
    $credentialName = $matches[2]
}
else {
    $returnMsg = "Missing Extra Parameters. Need dbname\credentialName"
    New-LogEntry "Returning: $($returnMsg)"
    Write-Host $returnMsg
    return
}

New-LogEntry "Logging on to $($address) as $($logonUserName)@$($logondomain)"
$PSLogon = New-Object -Typename PSCredential -ArgumentList "$($logonUserName)@$($logondomain)",($logonpass | ConvertTo-SecureString -AsPlainText -Force)
$RemoteSession = New-UsageLogon -address $address -PSLogon $PSLogon

if ($null -ne $RemoteSession -and $RemoteSession.GetType().Name -eq "PSSession") {
    $returnMsg = Update-Credential -RemoteSession $RemoteSession -address $address -dbname $dbname -credentialName $credentialName -newPass $newPass -username "$($userdomain)\$($username)"
}
else {
	New-LogEntry "RemoteSession: $($RemoteSession | Select * | Out-String)" 
    $returnMsg = "Logon Failure $($connection)"
}

New-LogEntry "Returning: $($returnMsg)"
Write-Host $returnMsg