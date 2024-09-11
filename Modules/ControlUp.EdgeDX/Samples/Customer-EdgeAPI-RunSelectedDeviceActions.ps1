#requires -Version 3.0
<#
.SYNOPSIS
    Runs selected scripts on devices

.DESCRIPTION
    The script prompts the user to choose a script - for demo purposes, pick one that doesn't make any drastic changes. It uses a filter to select the machines to run it on.

.NOTES
    The script assumes that the ControlUp.EdgeDX module is installed locally. Adjust this according to your environment.
    Ideally, install the module from github (or PSGallery, if supported) and set the module location to 'ControlUp.EdgeDX' to import the module

.MODIFICATION_HISTORY
    Anthony Green   - 2024-08-02 - Initial development
    Bill Powell     - 2024-09-09 - hardening for release
#>

[CmdletBinding()]
param (
    [string]$StringToMatchDeviceName = "FL*",                         # pattern to match device names
    [string]$ModuleLocation = 'C:\Projects\ControlUp.EdgeDX\ControlUp.EdgeDX.psd1'    # or set the module location to 'ControlUp.EdgeDX' if the ControlUp.EdgeDX module has been installed on the current device
)

[string]$spath = & { $myInvocation.ScriptName }
[string]$sdir = Split-Path -Path $spath -Parent

cls

Get-Module | Where-Object {$_.Name -eq 'ControlUp.EdgeDX'} | Remove-Module -Force   # unload module to make sure we start in a 'clean' state
Import-Module $ModuleLocation -Verbose

$logfilepath = $MyInvocation.MyCommand.Source.replace(".ps1",".log")
Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $false   # change the console logging here for debugging

Set-EDXSecrets


#region Endpoint and Filters for getting scripts
$endpoint = "scripts"
#endregion


#region Get a list of all scripts and provide UI for selection
$allscripts = Get-EDXData -Endpoint $endpoint
$scriptstorun = $allscripts.rows | Select-Object * | Out-GridView -PassThru -Title "Select the scripts to run"
If (!$scriptstorun){
    Write-EDXLog -Message "FAILURE: No scripts selected to be run"
    exit
}
Else {
    Write-EDXLog -Message "INFO: Scripts selected to be run - $($scriptstorun.name)"
}
#endregion


#region Endpoint and Filters for getting devices to run script on
$devicesendpoint = "devices"
$devicesfilters = @(
    @{ Field = "name"; Type = "like"; Value = $StringToMatchDeviceName }   # limit to machines with names that start with the string 'FL', or whatever is set in the parameter block of the script
)
#endregion


#region Get devices based on filters above
$devices = Get-EDXData -Endpoint $devicesendpoint -Filters $devicesfilters
Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $true
If ($devices.rows.Count -lt 1){
    Write-EDXLog -Message "FAILURE: No devices found"
    exit
}
Else {
    Write-EDXLog -Message "INFO: Devices where the script will run - $($devices.rows.name)"
}
Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $false
#endregion


#region Run selected scripts on devices
ForEach ($scripttorun in $scriptstorun){
    ForEach ($device in $devices.rows){
        $result = Invoke-EDXDeviceScript -ScriptId $scripttorun._id -DeviceId $device._id -DeviceName $device.name -ScriptName $scripttorun.name -RunForAllUsers
        Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $true
        Write-EDXLog -Message "INFO: Result - $($result)"
        Set-EDXLogfilePath -LogfilePath $logfilepath -LogToConsole $false
    }
}
#endregion

Write-Host -ForegroundColor Green "Now run the 'Customer-EdgeAPI-GetSystemEvents' script to validate the scripts you just ran."



