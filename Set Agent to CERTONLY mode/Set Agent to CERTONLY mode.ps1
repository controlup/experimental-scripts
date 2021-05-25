#requires -Version 3.0
<#
.SYNOPSIS       Sets ControlUp Agent service to cert only

.DESCRIPTION    Updates the ControlUp agent service to only allow connection using a certificate. See supplied link for more information and requirements

.CONTEXT        Machine

.LINK           https://support.controlup.com/hc/en-us/articles/360018408337-Certificate-Based-Agent-Authentication

.TAGS           $Machine, $agent, $Trigger

.HISTORY        19-04-2021 -Wouter Kursten - First Version
#>


$pathtoexe = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpAgent\*cuAgent.exe" -Recurse | Sort-Object LastWriteTime -Descending)[0]

$agentversion = $pathtoexe.versioninfo.fileversion
$usableversion = ($agentversion.replace(".","")).substring(0,5)
Write-Output "Agent is version $agentversion"
if ($usableversion -ge 82517){
    $service = get-WmiObject win32_service | ?{$_.Name -like '*cuagent*'} | select Name, DisplayName, State, PathName
    $pathname = $service.PathName
    if ($service.pathname -notlike "*/CERTONLY"){
        write-output "Original path in the service was: $pathname"
        write-output "Changing the service to /certonly"
        sc.exe config cuAgent binpath= "$pathtoexe /service /CERTONLY"
        $service = get-WmiObject win32_service | ?{$_.Name -like '*cuagent*'} | select Name, DisplayName, State, PathName
        $pathname = $service.PathName
        write-output "New path in the service is: $pathname"
        write-output "Please restart the ControlUp Agent for these changes to take effect."
    }
    elseif ($service.pathname -like "*/CERTONLY"){
        write-output "Service already has been configured to use /CERTONLY"
    }
}
else {
    write-output "Can't reconfigure the ControlUp agent as the agent is too old. Please update the agent first"
}
