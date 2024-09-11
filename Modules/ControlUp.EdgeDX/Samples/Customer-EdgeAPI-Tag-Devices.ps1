#requires -Version 3.0
<#
.SYNOPSIS
    Sets and clears a tag on a device

.DESCRIPTION
    The script enumerates the indexes for a tenant, and for each metric field writes the field name, the data type and the index to a csv file

.NOTES
    For demo purposes it might be good to set a breakpoint between the setting and clearing of the tag
    The script assumes that the ControlUp.EdgeDX module is installed locally. Adjust this according to your environment.
    Ideally, install the module from github (or PSGallery, if supported) and set the module location to 'ControlUp.EdgeDX' to import the module

.MODIFICATION_HISTORY
    Anthony Green   - 2024-08-02 - Initial development
    Bill Powell     - 2024-09-09 - hardening for release
#>

[CmdletBinding()]
param (
    [string[]]$TagsToAdd    = @("heythere"),
    [string[]]$TagsToDelete = @("heythere"),
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


#region Endpoint and Filters
$endpoint = "data/_devices"
$filters = @(
    @{ Field = "group"; Type = "like"; Value = "Lancaster" }
)
#endregion

#region Main Script Section
$devices = Get-EDXData -Endpoint $endpoint -Filters $filters
#$devices.rows | select-object name,group

# Example of adding a new tag
ForEach ($device in $devices.rows){
    Write-EDXLog -Message "INFO: Attempting to assign tags to device... Device: $($device.name) tags: $($tagstoadd)"
    # Can use "create" action to create tags and "delete" action to remove tags
    Set-EDXDeviceTag -Tags $TagsToAdd -Action "create" -ComputerName $device.name
}

Start-Sleep -Seconds 60

# Example of removing a tag
ForEach ($device in $devices.rows){
    Write-EDXLog -Message "INFO: Attempting to remove tags from device... Device: $($device.name) tags: $($tagstodelete)"
    # Can use "create" action to create tags and "delete" action to remove tags
    Set-EDXDeviceTag -Tags $TagsToDelete -Action "delete" -ComputerName $device.name
}

#endregion



