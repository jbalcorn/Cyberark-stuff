<#
    .SYNOPSIS
    PowershellTarget.ps1 - Cyberark CPM Plugin Target Template Script

    .DESCRIPTION
    Run by CyberArk.TPC.exe, passed the action, username, address and logonusername on the command line.  Communicates with TPC via STDIN and STDOUT, accepting
    the credentials via Console::Readline()

    This is intended as a base template for Powershell-based Target Account Platforms.

    .NOTES
    Requires PowershellProcess.ini and PowershellPrompts.ini to work with CyberArk.TPC.exe

    Create a Platform (copying Unix SSH seems to work best) and make sure CPM Plug-in is CyberArk.TPC.exe. (N.B. - this is case sensitive!)
    Under Additional Policy settings, change the ProcessFilename and PromptsFilename.
	
	.INPUTS
    None.  TPC Plugins use the Console to communicate

    .OUTPUTS
    None.  STDOUT and STDERR are connected to TPC and are used to communicate.

    .EXAMPLE
    bin\PowershellTest.ps1  -action 'verifypass' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .EXAMPLE
    # Pre-Change logon test action
    bin\PowershellTest.ps1  -action 'logon' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .EXAMPLE
    bin\PowershellTest.ps1  -action 'changepass' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .EXAMPLE
    # Pre-Reconcile logon test action
    bin\PowershellTest.ps1  -action 'prereconcile' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .EXAMPLE
    bin\PowershellTest.ps1  -action 'reconcilepass' -address 'server.fqdn' -username 'localuser' -logonusername 'admin'

    .LINK
    https://github.com/jbalcorn/Cyberark-stuff
#>
Param(
    [Parameter(Mandatory = $false)][string]$action,
    [Parameter(Mandatory = $true)][string]$address,
    [Parameter(Mandatory = $true)][string]$username,
    [Parameter(Mandatory = $true)][string]$logonUserName
)

# Set this to a full path name and make sure the path is created and writable
$logfile = 'PowershellTarget.log'

if ($null -eq $action -or $null -eq $address -or $null -eq $username -or $null -eq $logonUserName) {
    #
    # Note that the phrase "Missing arguments" is recognized by PowershellPrompts.ini and the [transitions] returns a specifec error to the CPM
    Write-Host "Missing arguments. Usage: PowershellTarget.ps1 -action <action> -address <address> -username <username> -logonuser <logonuser>"
    return
}

function isChangeAction {
    Param(
        [Parameter(Mandatory=$true)]$action
    )
	if ($action -match 'verifypass') {
		return $false
	}
	return $true
}

function isVerifyAction {
	Param(
		[Parameter(Mandatory=$true)]$action
	)
	if ($action -match 'verifypass') {
		return $true
	}
	else {
		return $false
	}
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

function New-Logon {
<#
    Modify this function if the process requires a logon before manage, for example a REST API.  Template just passes back a PSCredential object that can be used
#>
    param(
        $address,
        $username,
        $logonPass
    )
    $auth = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $username,($logonPass | ConvertTo-SecureString -AsPlainText -Force )
    if (isVerifyAction($action)) {
        # To fail verify and force reconciliation
        # $auth = $false
    }
    return $auth
}

function Update-TargetPassword {
    Param(
        $auth,
        $address,
        $username,
        $oldpass,
        $newpass
    )
    $returnMsg = "Script Result: Success"
    #
    # Process for updating password.  Don't log passwords in production, this is just a template
    New-LogEntry "Authentication Creds: $($auth.Username) $($auth.GetNetworkCredential().Password)"
    New-LogEntry "Address: $($address)"
    New-LogEntry "Old Creds: $($username) $($oldpass)"
    New-LogEntry "New Creds: $($username) $($newpass)"
    ###
    return $returnMsg
}

New-LogEntry "PowershellTarget Called: $($action) $($address) $($username) $($logonusername)" 


Write-Host "Enter the logon password:"
$logonpass = [Console]::ReadLine()

if (isChangeAction -action $action) {

    Write-Host "Enter the old password:"
    $oldpass = [Console]::ReadLine()

    Write-Host "Enter the new password:"
    $newpass = [Console]::ReadLine()

}
Write-Host "Input Complete"

$auth = New-Logon -address $address -username $logonUserName -logonPass $logonpass

if ($auth) {
	$returnMsg = 'Script Result: Success'
	if (-Not (isVerifyAction($action))) {
		$returnMsg = Update-TargetPassword -auth $auth -address $address -username $username -oldpass $oldpass -newpass $newpass
	}
}
else {
    if (isVerifyAction($action)) {
        # This forces a 2114 return code which will cause the CPM to schedule a reconciliation
        $returnMsg = "Invalid Username or Password specified."
    }
    else {
        $returnMsg = "Authentication Failed"
    }
}

New-LogEntry "Returning: $($returnMsg)"
Write-Host $returnMsg