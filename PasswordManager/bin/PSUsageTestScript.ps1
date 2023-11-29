<#
    .SYNOPSIS
    Cyberark CPM Usage Plugin Test Script

    .DESCRIPTION
    Run by CyberArk.TPC.exe, passed the action, username, address and logonusername on the command line.  Communicates with TPC via STDIN and STDOUT, accepting
    the credentials via Console::Readline()

    This is intended as a template for Powershell-based Usages.  

    .PARAMETER action
    Required by TPC.  For a usage, only valid action is 'changepass'

    .PARAMETER address
    Required by TPC.  Address of server related to whatever usage this is

    .PARAMETER username
    required by TPC.  This will be the master object username. 

    .PARAMETER logonusername
    required by TPC.  This will be the authentication user to reach out to server. the TPC will provide the logon username if specified, 
    otherwise this will be the master object username.

    .PARAMETER extraparameters
    Provided by the Platform usage process.  This contains whatever other inforamtion is needed - one example would be a Scheduled Task on the server 
    to run on password changes

    .NOTES
    Requires PSUsageProcess.ini and PSUsagePrompts.ini to work with CyberArk.TPC.exe
	
	The only valid action for a Usage/Service is 'changepass'.   While pmpass and pmnewpass are available, they will always be the same and equal to the new password.

    'ScriptName' and 'ExtraParameters' would need to be added in PrivateArk under "Server File Categories" and then added to the usage platform.
    
    .INPUTS
    None.  TPC Plugins use the Console to communicate

    .OUTPUTS
    None.  STDOUT and STDERR are connected to TPC and are used to communicate.

    .EXAMPLE
    bin\PSUsageTestScript.ps1  -taskname 'changepass' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .LINK
    https://github.com/jbalcorn/Cyberark-stuff
#>
Param(
    [Parameter(Mandatory = $false)][string]$action,
    [Parameter(Mandatory = $true)][string]$address,
    [Parameter(Mandatory = $true)][string]$username,
    [Parameter(Mandatory = $true)][string]$logonUserName,
    [Parameter(Mandatory = $true)][string]$ExtraParameters

)
$ThisScriptRequiresExtraParameters = $false

# Set this to a full path name and make sure the path is created and writable
$logfile = 'PSUsageTestScript.log'


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
    "$(Get-Date) $($msg)" | Out-File -Append -FilePath $logfile
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
    $auth = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $username,($logonPass | ConvertTo-SecureString -AsPlainText -Force )
    return $auth
}

function Update-UsagePassword {
    Param(
        $auth,
        $address,
        $username,
        $newpass
    )
    $returnMsg = "Script Result: Success"
    #
    # Process for updating password.  Don't log passwords in production
    New-LogEntry "Authentication Creds: $($auth.Username) $($auth.GetNetworkCredential().Password)"
    New-LogEntry "Address: $($address)"
    New-LogEntry "New Creds: $($username) $($newpass)"
    ###
    return $returnMsg
}

New-LogEntry "PSUsageTestScript Called: $($action) $($address) $($username) $($logonusername)" 

if ($null -eq $action -or $null -eq $address -or $null -eq $username -or $null -eq $logonUserName -or ($null -eq $ExtraParameters -and $ThisScriptRequiresExtraParameters)) {
    Write-Host "Missing arguments. Usage: PSUsageTestScript.ps1 -action <action> -address <address> -username <username> -logonuser <logonuser> [-extraparameters <extraparameters>]"
    return
}

Write-Host "Enter the logon password:"
$logonpass = [Console]::ReadLine()

if (isChangeAction($action)) {
    Write-Host "Enter the new password:"
    $newpass = [Console]::ReadLine()
}
Write-Host "$($action) Input Complete"

$auth = New-UsageLogon -address $address -username $logonUserName -logonPass $logonpass

if ($auth) {
    $returnMsg = Update-UsagePassword -auth $auth -address $address -username $username -newpass $newpass
}
else {
    $returnMsg = "Logon Failure"
}

New-LogEntry "Returning: $($returnMsg)"
Write-Host $returnMsg