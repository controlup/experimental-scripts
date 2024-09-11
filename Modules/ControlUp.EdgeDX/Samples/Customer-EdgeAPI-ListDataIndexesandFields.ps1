#requires -Version 3.0
<#
.SYNOPSIS
    Creates a list of metrics collected

.DESCRIPTION
    The script enumerates the indexes for a tenant, and for each metric field writes the field name, the data type and the index to a csv file

.NOTES
    The script assumes that the ControlUp.EdgeDX module is installed locally. Adjust this according to your environment.
    Ideally, install the module from github (or PSGallery, if supported) and set the module location to 'ControlUp.EdgeDX' to import the module

.MODIFICATION_HISTORY
    Anthony Green   - 2024-08-02 - Initial development
    Bill Powell     - 2024-09-09 - hardening for release
#>

[CmdletBinding()]
param (
    [string]$MetricsCSVFile = "metricslist.csv",                      # this file will be created in the same folder that the script resides in.
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

$endpoint = "data"
#endregion

#region Main Script Section
$responses = Get-EDXData -Endpoint $endpoint
#$devices.rows | select-object name,group,tags

$dataindexes = $responses.name | ForEach-Object {
    $_ -replace "_\d{8}$", ""
} | Select-Object -Unique

$metricslist = New-Object System.Collections.ArrayList

ForEach ($dataindex in $dataindexes){
    $mappings = (Get-EDXData -Endpoint "data/$dataindex" -SchemaOnly).mappings
    $metricslist.AddRange(($mappings | select name,type,@{l="index";e={$dataindex}}))
}

$MetricsCSVPath = Join-Path -Path $sdir -ChildPath $MetricsCSVFile
$metricslist | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $MetricsCSVPath

#endregion

