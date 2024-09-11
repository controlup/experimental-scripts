#requires -Version 3.0
<#
.SYNOPSIS
    Updates device assignments to groups

.DESCRIPTION
    The script prompts the use to choose a CSV file which contains a list of device -> group mappings..

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

#region Main Script Section
$devicegroupoverride = "TEST" # If the CSV contains customised device group names for each device they will be used, otherwise this will be used for all devices.
$csvData = Import-EDXCSVWithUI # The CSV should contain a "name" column, and optionally a devicegroup column.

ForEach ($device in $csvdata){
    If ($device.devicegroup) {
        # Make sure we have devicegroup and then we can try grouping the machine
        Write-EDXLog -Message "INFO: Attempting to assign group to device... Device: $($device.name) Group: $($device.devicegroup)"
        Set-EDXDeviceGroup -ComputerName $device.name -DeviceGroup $device.devicegroup
    }
    Else {
        If ($devicegroupoverride){
            Write-EDXLog -Message "INFO: No devicegroup value found in CSV for $($device.name). Using the devicegroupoverride variable $($devicegroupoverride)."
            Set-EDXDeviceGroup -ComputerName $device.name -DeviceGroup $devicegroupoverride
        }
        Else {
            Write-EDXLog -Message "FAILURE: No devicegroupname value found in CSV or devicegroupoverride variable for $($device.name)."
        }
    }
}
#endregion


