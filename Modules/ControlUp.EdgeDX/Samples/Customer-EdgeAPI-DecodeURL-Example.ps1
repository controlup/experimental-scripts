#requires -Version 3.0
<#
.SYNOPSIS
    Convert filters from URL to powershell snippet

.DESCRIPTION
    The script demonstrates the use of the EdgeDX API module 'ControlUp.EdgeDX' cmdlets 'Get-EDXDecodedURL' and 'Convert-EDXDecodedURLToFilter' to convert filter parameters from a URL (e.g. from a Postman session) into a powershell code snippet.

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
$url = "https://dex-05b01234e2cb3ca087c387dab02d34b5.sip.controlup.com/api/data/_devices?page=1&size=100&filters%5B0%5D%5Bfield%5D=_updated&filters%5B0%5D%5Btype%5D=%3E%3D&filters%5B0%5D%5Bvalue%5D=2024-07-29T23%3A00%3A00.000Z&filters%5B1%5D%5Bfield%5D=_updated&filters%5B1%5D%5Btype%5D=%3C%3D&filters%5B1%5D%5Bvalue%5D=2024-07-30T22%3A59%3A59.999Z&filters%5B2%5D%5Bfield%5D=group&filters%5B2%5D%5Btype%5D=like&filters%5B2%5D%5BapiColumnType%5D=text&filters%5B2%5D%5Bvalue%5D=tbd%7C%7C%21%21%2A%7C%7CUngrouped&sorters%5B0%5D%5Bfield%5D=_created&sorters%5B0%5D%5Bdir%5D=desc&export=false"
#$decodedURL = Get-EDXDecodedURL -url $url
#$filtercode = Convert-EDXDecodedURLToFilter -QueryParameters $decodedURL.QueryParameters
$filtercode = Get-EDXDecodedURL -url $url | Convert-EDXDecodedURLToFilter
Write-Output "`nCopy and paste the below filter code into your API script:`n"
$filtercode
Write-Output ""
#endregion



