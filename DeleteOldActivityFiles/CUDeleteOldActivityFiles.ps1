<#
.SYNOPSIS
    ControlUp Old Activity Files cleanup script
.DESCRIPTION
    This script cleans the old Activity Files from the disk
.CONTEXT
    ControlUp
.MODIFICATION_HISTORY
    Samuel Legrand - 20/08/20 - Original code
.EXAMPLE
        CUDeleteOldActivityFiles.ps1 -FolderPath 'C:\temp' -NumberOfDays 30

.NOTES
    Version:        1.0
    Author:         Samuel Legrand
    Creation Date:  2020-08-20
    Updated:        

    Purpose:        Cleaning old Monitor's Activity Files in ControlUp On Premises deployment
        
    Copyright (c) All rights reserved.
#>
[CmdletBinding()]
Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Please provide the path of the folder to cleanup'
        )]
        [ValidateNotNullOrEmpty()]
        $FolderPath,
        [Parameter(
            Position=1, 
            Mandatory=$false, 
            HelpMessage='Please provide the number of days you want to keep your Activity Files (Default = 30)'
        )]
        [int] $NumberOfDays = 30
    )

if (Test-Path $FolderPath){
    write-output "Cleaning folder $FolderPath - All files older than $NumberOfDays day(s)"
    $Count = 0
    $Megs = 0
    $Files = Get-ChildItem -Path $FolderPath 
    foreach ($File in $Files){
        if ($File.LastWriteTime -lt (Get-Date).AddDays(-$NumberOfDays))
        {
            Remove-Item $FolderPath\$File -Force
            $Count += 1
            $Megs += $File.Length
        }
    }
    Write-Output "Script has removed $count file(s) and saved $([math]::Round($($megs/1048576))) MB."
}
else {
    Write-Output 'The folder path provided is not valid'
}