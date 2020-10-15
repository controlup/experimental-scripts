<#
.SYNOPSIS
    Retrieve the encoder of a VMware Blast user session
.DESCRIPTION
    Retrieve the encoder of a VMware Blast user session by looking at the following log file "C:\ProgramData\VMware\VMware Blast\Blast-Worker-SessionId1.log"
.CONTEXT
    ControlUp
.MODIFICATION_HISTORY
    Samuel Legrand - 25/09/20 - Original code
.EXAMPLE
        Get-VMwareBlast-Encoder.ps1 

.NOTES
    Version:        1.0
    Author:         Samuel Legrand
    Creation Date:  2020-09-25
    Updated:        

    Purpose:        Retrieve the encoder of a VMware Blast user session
        
    Copyright (c) All rights reserved.
#>
# Script variables
$bol = $false
$maxretry = 10
$waitbetweentries = 1
$counter = 1 

# As VMware is using the file very frequently, try to copy the log file in the temp folder
while (($bol -eq $false) -and ($counter -le $maxretry)){
    try {
        Copy-Item "C:\ProgramData\VMware\VMware Blast\Blast-Worker-SessionId1.log" $ENV:TEMP -ErrorAction Stop
        $bol = $true
    }
    catch{
        Start-Sleep -Seconds $waitbetweentries
        $bol = $false
        $counter+=1
    }
}

# Check if the file as been successfully copied and then analyze it
if ($bol){
    $VNCRegionEncoders = Get-Content "$ENV:TEMP\Blast-Worker-SessionId1.log" | Where-Object { $_.Contains("VNCRegionEncoder") }
    $LastVNCRegionEncoder = $VNCRegionEncoders[$VNCRegionEncoders.Count - 1]
    Write-Output $LastVNCRegionEncoder.Substring($LastVNCRegionEncoder.IndexOf("VNCRegionEncoder_Create")).Split(".")[0]
    Write-Output $LastVNCRegionEncoder.Substring($LastVNCRegionEncoder.IndexOf("VNCRegionEncoder_Create")).Split(".")[1]
}
else {
    Write-Error "Impossible to retrieve the file after $maxretry tries"
}