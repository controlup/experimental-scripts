<#  
.SYNOPSIS
      This script Merge the ControlUp exports in one file per day.
.DESCRIPTION
      This script Merge the ControlUp exports in one file per day.
.PARAMETER 
      This script has 2 parameters:
      SourceFolder - The folder where the original exports are located
      DestFolder - The folder where the merged exports should be created 
.EXAMPLE
        ./Merge_ControlUp_Exports.ps1 "c:\exports" "c:\newexports"  
.LINK
        See http://www.ControlUp.com
#>
[CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true
        )]
        [string] $SourceFolder, 
        [Parameter(
            Position=1, 
            Mandatory=$true
        )]
        [string] $DestFolder
    )

    if ((Test-Path $SourceFolder) -and (Test-Path $DestFolder))
    {
        $ExportFiles = Get-ChildItem -Path $SourceFolder -Filter *.csv
        foreach($ExportFile in $ExportFiles){
            #CUMONITOR01.controlUp.demo-ControlUp_Machines_09_29_2020_18_00_37.csv
            $Temp = $($ExportFile.Name.Split("_")).Replace(".csv","")
            $ReportName = $Temp[1]
            $Date = "$($Temp[2])_$($Temp[3])_$($Temp[4])"
            $DateHour = "$($Temp[2])_$($Temp[3])_$($Temp[4])_$($Temp[5])_$($Temp[6])_$($Temp[7])"
            $DestFileName = "$($DestFolder)\$($Date)_$($Reportname).csv"
            Get-Content $ExportFile.FullName| Select-Object -Skip 1 | ConvertFrom-Csv -Delimiter "," | Select-Object *,@{Name='ExtractTime';Expression={$DateHour}} | Export-Csv $DestFileName -NoTypeInformation -Append
            
        }

    }
    else {
        Write-Error "At least one of the folder (Source or Destination) doesn't exist, please check the provided parameters"
    }