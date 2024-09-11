#requires -Version 3.0
<#
.SYNOPSIS
    Fetch events from EdgeDX event log

.DESCRIPTION
    The script demonstrates the basic use of the EdgeDX API module 'ControlUp.EdgeDX' to obtain events from the EdgeDX event log - in this case, indicating what scripts have been run recently.
    Note the use of filters to restrict the number of records returned.

.NOTES
    The script assumes that the ControlUp.EdgeDX module is installed locally. Adjust this according to your environment.
    Ideally, install the module from github (or PSGallery, if supported) and set the module location to 'ControlUp.EdgeDX' to import the module

.MODIFICATION_HISTORY
    Anthony Green   - 2024-08-02 - Initial development
    Bill Powell     - 2024-09-09 - hardening for release
#>

[CmdletBinding()]
param (
    [string]$ModuleLocation = 'C:\Projects\ControlUp.EdgeDX\ControlUp.EdgeDX.psd1'    # or set the module location to 'ControlUp.EdgeDX' if the ControlUp.EdgeDX module has been installed on the current device
)

cls

Get-Module | Where-Object {$_.Name -eq 'ControlUp.EdgeDX'} | Remove-Module -Force   # unload module to make sure we start in a 'clean' state
Import-Module $ModuleLocation -Verbose

$logfilepath = $MyInvocation.MyCommand.Source.replace(".ps1",".log")
Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $false   # change the console logging here for debugging

Set-EDXSecrets

#region Endpoint and Filters
$Now = Get-Date
$DaysAgo = $Now.AddDays(-30)

$endpoint = "events"
$filters = @(
    @{ Field = "_created"; Type = ">="; Value = (ConvertTo-EDXDateTime $DaysAgo) }
    @{ Field = "_created"; Type = "<="; Value = (ConvertTo-EDXDateTime $Now) }
    @{ Field = "title"; Type = "like"; Value = "Action" }
)
#endregion


#region Main Script Section
$events = Get-EDXData -Endpoint $endpoint -Filters $filters
$sentscriptsarray = @()
$sentscripts = $events.rows | Sort-Object _created | Where-Object {$_.description -like "*RUN_SCRIPT_V2*"}
ForEach ($sentscript in $sentscripts){
    $sentscriptdetails = Get-EDXActionDescription -inputString $sentscript.description
    $sentscriptdetails | Add-Member -MemberType NoteProperty -Name "Device" -Value $sentscript.associated_name
    $sentscriptdetails | Add-Member -MemberType NoteProperty -Name "DateTimeSent" -Value $sentscript._created

    # Set the filter to get the exact script using the script_id field
    $scriptfilter = @(
        @{ Field = "_id"; Type = "="; Value = $($sentscriptdetails.script_id) }
    )
    $tenantscript = Get-EDXData -Endpoint "scripts" -filters $scriptfilter
    $sentscriptdetails | Add-Member -MemberType NoteProperty -Name "ScriptName" -Value $tenantscript.rows.name
    $sentscriptsarray += $sentscriptdetails
}

$sentscriptsarray | Out-GridView
#endregion

exit 0

#
# Bonus section - check the help for all of the ControlUp.EdgeDX commands
#

Get-Module | Where-Object {$_.Name -eq 'ControlUp.EdgeDX'} | Remove-Module -Force   # unload module to make sure we start in a 'clean' state
Import-Module $ModuleLocation -Verbose

cls; Get-Command -Module ControlUp.EdgeDX | ForEach-Object {
    Write-Host -ForegroundColor Cyan "==========================================================================================" ; 
    Write-Host -ForegroundColor cyan $_.Name; 
    Get-Help $_.Name -Full
}


