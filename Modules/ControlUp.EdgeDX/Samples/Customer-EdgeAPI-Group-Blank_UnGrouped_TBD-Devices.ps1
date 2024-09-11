#requires -Version 3.0
<#
.SYNOPSIS
    Get list of ungrouped devices

.DESCRIPTION
    The script checks the _devices index for devices where the group field is null or set to ungrouped
    The logic is in the filter.

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
$endpoint = "data/_devices"
$filters = @(
    @{ Field = "group"; Type = "like"; Value = "tbd||!!*||Ungrouped" }    # || is the 'or' operator. !! is negation, so !!* represents 'not anything'. i.e. null
)
#endregion

#region Main Script Section
$devices = Get-EDXData -Endpoint $endpoint -Filters $filters
$devices.rows | select-object name,group

#endregion



