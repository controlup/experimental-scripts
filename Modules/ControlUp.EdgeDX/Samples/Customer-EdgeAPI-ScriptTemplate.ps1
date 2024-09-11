<# EdgeAPI Script Template

The purpose for this script is to provide a framework where customers can utilise API queries easily

Valid endpoints can be found here - https://apidoc.sip.controlup.com/
This script uses filters - Please read https://apidoc.sip.controlup.com/#tag/Devices/operation/list-devices for more info on filters
In general use... type = "like" for text fields, type = <, <=, =, !=, <=, or > for number and date fields, and type = "true", "false" for boolean fields
If wanting the negative of like (notlike) then use !! at the beginning of the value field
If wanting to filter on multiple "OR" values, then separate values using 2 pipe symbols ||.  Check example 2.
If wanting to filter on multiple "AND" values, then separate values using 2 ampersand symbols &&.
If filtering on dates the dates need to be in zulu time

#>

<#  1. Example endpoint and filter to query the main "devices" endpoint to get information for a device.  Note the field used to find the device is "name"
    $endpoint = "devices"
    $filters = @(
        @{ Field = "name"; Type = "like"; Value = "testdevice" }     # The device name is stored in the "name" field when querying the main "devices" endpoint
        @{ Field = "hw_cpu_max_speed"; Type = ">"; Value = "1700" }
        @{ Field = "agent_auto_update"; Type = "boolean"; Value = "true" }
    )
#>

<#  2. Example endpoint and filter to query the app_focus data index to get information for 2 devices  Note the field used to find the device is "_device_name"
    $endpoint = "data/app_focus" # Data index endpoints normally begin with data/ followed by the name of the data index
    $filters = @(
        @{ Field = "_device_name"; Type = "like"; Value = "testdevice1||testdevice2" }   # The device name is normally stored in the _device_name field in data indexes
    )
#>

<#  3. Example endpoint and filter to query the _highresourceprocs data index to get information for a device between 2 times/dates
    $endpoint = "data/_highresourceprocs"
    $hoursback = 24
    $start = (Get-Date).AddHours(-$hoursback).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $end = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    $filters = @(
        @{ Field = "_created"; Type = ">="; Value = $start },
        @{ Field = "_created"; Type = "<="; Value = $end },
        @{ Field = "_device_name"; Type = "like"; Value = "testdevice" }
    )
#>


[CmdletBinding()]
param (
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

$Now = Get-Date

<# Endpoint and Filters - Start #>
$endpoint = "devices"
$filters = @(
@{ Field = "active_usernames"; Type = "like"; Value = "Administrator" }
@{ Field = "_updated"; Type = "<="; Value = (ConvertTo-EDXDateTime $Now) }
@{ Field = "_updated"; Type = ">="; Value = "2024-07-16T23:00:00.000Z" }
)



$filters = @(
@{ Field = "active_usernames"; Type = "like"; Value = "*Bill*" }
@{ Field = "_updated"; Type = "<="; Value = (ConvertTo-EDXDateTime $Now) }
@{ Field = "_updated"; Type = ">="; Value = "2024-01-16T23:00:00.000Z" }
)
<# Endpoint and Filters - End #>


<# Main Script Section - Start #>
$response = Get-EDXData -Endpoint $endpoint -Filters $filters
$response.rows # Results of api queries are stored in rows
<# Main Script Section - End #>



