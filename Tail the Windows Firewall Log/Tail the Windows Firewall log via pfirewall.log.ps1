     <#
    .SYNOPSIS
        Enables Windows Firewall logging and streams the logfile

    .DESCRIPTION
        Enables Windows Firewall logging and streams the logfile
		
    .PARAMETER  <ComputerName <string>>
        Name of the machine to monitor the firewall log

    .PARAMETER  <EnableLogging <boolean>>
        Set to $True so logging will be enabled. Set to $False and logging will be disabled and the script will terminate.

    .EXAMPLE
        . .\TailWindowsFirewallLog.ps1 -ComputerName HYPPVS2019-001 -EnableLogging $true
        Enables logging the Windows firewall and starts tailing the log file

    .EXAMPLE
        . .\TailWindowsFirewallLog.ps1 -ComputerName HYPPVS2019-001 -EnableLogging $false
        Disables logging of the Windows firewall and than exits

    .CONTEXT
        Console

    .MODIFICATION_HISTORY
        Created TTYE : 2020-09-11


    AUTHOR: Trentent Tye
#>

[CmdLetBinding()]
Param (
    [Parameter(Mandatory=$true,HelpMessage='Enter the name of the Machine')][ValidateNotNullOrEmpty()] [string]$ComputerName,
    [Parameter(Mandatory=$true,HelpMessage='Enable Logging')][ValidateSet('True','False')][ValidateNotNullOrEmpty()] [string]$EnableLogging
)

if ($EnableLogging -eq "True") {
    $Logging = $true
} else {
    $Logging = $false
}

if ($Logging -eq $false) {
    $SetupFirewall = Invoke-Command -ScriptBlock {
        $FirewallProfiles = Get-NetFirewallProfile
        foreach ($profile in $FirewallProfiles) {
            Set-NetFirewallProfile -LogBlocked False | Out-Null
            Set-NetFirewallProfile -LogAllowed False | Out-Null
            Set-NetFirewallProfile -LogIgnored False | Out-Null
        }
    } -ComputerName $ComputerName
    Write-Output "Disabled Firewall Logging"
    exit
}

$SetupFirewall = Invoke-Command -ScriptBlock {
    $FirewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $FirewallProfiles) {
        Set-NetFirewallProfile -LogBlocked True | Out-Null
        Set-NetFirewallProfile -LogAllowed True | Out-Null
        Set-NetFirewallProfile -LogIgnored True | Out-Null
    }
    return $FirewallProfiles.LogFileName
} -ComputerName $ComputerName

#The SetupFirewall variable should have only returned the log file locations. We'll see if they are the same location and error if not
#because I haven't setup error handling to deal with multiple files at one
$FirewallLogFile = $SetupFirewall | Sort-Object -Unique
if ($FirewallLogFile.count -gt 1) {
    Write-Error "$($FirewallLogFile.count) firewall log files found, unable to continue."
    Write-Error "$FirewallLogFile"
}

#We need to format the log file path text as we will access them remotely
$remoteLogPath = $FirewallLogFile.replace("%systemroot%","\\$Computername\C$\Windows")

if (-not(Test-Path $remoteLogPath)) {
    Write-Error "Unable to access log file remotely. Attempted to connect from path : $remoteLogPath"
    return 1
}



$ScriptBlock = {
    function Colorize-BISFLog ($line) {
    $i = 0
    foreach ($splitobj in $line.Split(" ","9")) {
        $i++
        ## Using Console instead of Write-Host for performance
        if ($i -eq 1) { [Console]::ForegroundColor = [System.ConsoleColor]::DarkGray
                        [Console]::Write("$splitobj ") }
        if ($i -eq 2) { [Console]::ForegroundColor = [System.ConsoleColor]::Gray
                        [Console]::Write("$splitobj ") }
        if ($i -eq 3) { 
            switch ($splitobj) {
                "DROP" { [Console]::ForegroundColor = [System.ConsoleColor]::Magenta
                         [Console]::Write("$splitobj ")}
                "ALLOW" {[Console]::ForegroundColor = [System.ConsoleColor]::Green
                         [Console]::Write("$splitobj ")}
                default {[Console]::ForegroundColor = [System.ConsoleColor]::Gray
                         [Console]::Write("$splitobj ")}
            }
        }
        if ($i -eq 4) {
            switch ($splitobj) {
                "TCP" {   [Console]::ForegroundColor = [System.ConsoleColor]::Yellow
                          [Console]::Write("$splitobj ")}
                "UDP" {   [Console]::ForegroundColor = [System.ConsoleColor]::Cyan
                          [Console]::Write("$splitobj ")}
                default { [Console]::ForegroundColor = [System.ConsoleColor]::Gray
                          [Console]::Write("$splitobj ")}
            }

        }
        if ($i -eq 5 -or $i -eq 6) { [Console]::ForegroundColor = [System.ConsoleColor]::White
                                     [Console]::Write("$splitobj ")}
        if ($i -eq 7) { [Console]::ForegroundColor = [System.ConsoleColor]::Yellow
                        [Console]::Write("$splitobj ")}
        if ($i -eq 8) { [Console]::ForegroundColor = [System.ConsoleColor]::White
                        [Console]::Write("$splitobj ")}
        if ($i -eq 9) { [Console]::ForegroundColor = [System.ConsoleColor]::Gray
                        [Console]::WriteLine("$splitobj ")}
        }
    }

    Get-Content -wait "$($args[0])" -tail 50 | Where-Object {Colorize-BISFLog($_)}
    pause
}

$bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBlock)
$encodedCommand = [Convert]::ToBase64String($bytes)
Write-Verbose "EncodedCommand: `n $encodedCommand"

$Random = Get-Random

<#
ok, so to spawn a new powershell.exe with arguments that can tie into the encoded command, we need encoded arguments
the problem is ConvertTo-XML fails because the XML format created is not accepted by Powershell.exe.  It needs it in
the same format as Export-CLIXML.  But ExportCliXML does not have a simple export to an object, so we need to export
to a file and reimport it.  But the EncodedArguments parameter requires a arrayList --> within a array list.
going straight to a single array list fails.  So we need to create an array list, and then create another.  In the second
ArrayList we put in our arguments and then embed that arraylist within the original.  THEN we can export it back out so that
the XML is created correctly.
#>
$rootEncodedCommandArray = New-Object System.Collections.ArrayList
$ArrayListObject = New-Object System.Collections.ArrayList
$ArrayListObject.Add($remoteLogPath) | Out-Null
$rootEncodedCommandArray.Add($ArrayListObject) | Out-Null
$rootEncodedCommandArray | Export-Clixml "$env:temp\$Random.xml"
$ArgumentsInXML = Get-Content "$env:temp\$Random.xml"

$bytes = [System.Text.Encoding]::Unicode.GetBytes($ArgumentsInXML)
$encodedArguments = [Convert]::ToBase64String($bytes)
Write-Verbose "EncodedArgument: `n $encodedArguments"

Start-Process powershell.exe -ArgumentList ("-noprofile -encodedCommand", $encodedCommand, "-encodedarguments", $encodedArguments, "-inputformat xml -outputformat text" )

