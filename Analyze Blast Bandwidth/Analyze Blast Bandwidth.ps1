
<#  
.SYNOPSIS
      This script shows the network bandwidth used by a given VMware Horizon Blast session.
.DESCRIPTION
      This script measures the bandwidth of a given active VMware Horizon Blast session, and breaks down the bandwidth consumption into the most useable Blast virtual channels.
      The output shows the bandwidth usage in kbps (kilobits per second) of each virtual channel and the total session.
.PARAMETER 
      This script has 3 parameters:
      ServerName - The target server that the script should run on.
      Session ID - The session ID of the session
      UserName - The UserName of the session. 
.EXAMPLE
        In order to analyze a session remotely (needs some rights)
        ./"Analyze Blast Bandwidth.ps1" "HZNDESKPOOL1-001" "1" "controlup\samuel.legrand" 
        In order to analyze the current session (no specific right needed)
        ./"Analyze Blast Bandwidth.ps1" 
.OUTPUTS
        A list of the measured virtual channels with the bandwidth consumption in kbps.
.LINK
        See http://www.ControlUp.com
#>
[CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$false
        )]
        [int] $SessionID = [System.Diagnostics.Process]::GetCurrentProcess().SessionId, 
        [Parameter(
            Position=1, 
            Mandatory=$false
        )]
        [string] $UserName = $ENV:USERNAME
    )

$Samples = 2
$SampleInterval = 10



$Counters = Get-Counter -Counter "\VMware Blast Session Counters(session id: $SessionID; (main))\Received Bytes","\VMware Blast Session Counters(session id: $SessionID; (main))\Transmitted Bytes","\VMware Blast Audio Counters(session id: $SessionID; Channel: Audio; (main))\Received Bytes","\VMware Blast Audio Counters(session id: $SessionID; Channel: Audio; (main))\Transmitted Bytes","\VMware Blast CDR Counters(session id: $SessionID; Channel: CDR; (main))\Received Bytes","\VMware Blast CDR Counters(session id: $SessionID; Channel: CDR; (main))\Transmitted Bytes","\VMware Blast Clipboard Counters(session id: $SessionID; Channel: Clipboard; (main))\Received Bytes","\VMware Blast Clipboard Counters(session id: $SessionID; Channel: Clipboard; (main))\Transmitted Bytes","\VMware Blast HTML5 MMR Counters(session id: $SessionID; Channel: HTML5MMR; (main))\Received Bytes","\VMware Blast HTML5 MMR Counters(session id: $SessionID; Channel: HTML5MMR; (main))\Transmitted Bytes","\VMware Blast Imaging Counters(session id: $SessionID; Channel: Imaging; (main))\Received Bytes","\VMware Blast Imaging Counters(session id: $SessionID; Channel: Imaging; (main))\Transmitted Bytes","\VMware Blast RTAV Counters(session id: $SessionID; Channel: RTAV; (main))\Received Bytes","\VMware Blast RTAV Counters(session id: $SessionID; Channel: RTAV; (main))\Transmitted Bytes","\VMware Blast Serial Port and Scanner Counters(session id: $SessionID; Channel: SerialPort-and-Scanner; (main))\Received Bytes","\VMware Blast Serial Port and Scanner Counters(session id: $SessionID; Channel: SerialPort-and-Scanner; (main))\Transmitted Bytes","\VMware Blast Session Counters(session id: $SessionID; (main))\Estimated Bandwidth (Uplink)","\VMware Blast Session Counters(session id: $SessionID; (main))\Jitter (Uplink)","\VMware Blast Session Counters(session id: $SessionID; (main))\Packet Loss (Uplink)","\VMware Blast Session Counters(session id: $SessionID; (main))\RTT" -SampleInterval $SampleInterval -MaxSamples $Samples
$TotalReceived = ($Counters[1].CounterSamples[0].CookedValue - $Counters[0].CounterSamples[0].CookedValue)/1024
$TotalSent = ($Counters[1].CounterSamples[1].CookedValue - $Counters[0].CounterSamples[1].CookedValue)/1024
$AudioReceived = ($Counters[1].CounterSamples[2].CookedValue - $Counters[0].CounterSamples[2].CookedValue)/1024
$AudioSent = ($Counters[1].CounterSamples[3].CookedValue - $Counters[0].CounterSamples[3].CookedValue)/1024
$CDRReceived = ($Counters[1].CounterSamples[4].CookedValue - $Counters[0].CounterSamples[4].CookedValue)/1024
$CDRSent = ($Counters[1].CounterSamples[5].CookedValue - $Counters[0].CounterSamples[5].CookedValue)/1024
$ClipboardReceived = ($Counters[1].CounterSamples[6].CookedValue - $Counters[0].CounterSamples[6].CookedValue)/1024
$ClipboardSent = ($Counters[1].CounterSamples[7].CookedValue - $Counters[0].CounterSamples[7].CookedValue)/1024
$HTML5MMRReceived = ($Counters[1].CounterSamples[8].CookedValue - $Counters[0].CounterSamples[8].CookedValue)/1024
$HTML5MMRSent = ($Counters[1].CounterSamples[9].CookedValue - $Counters[0].CounterSamples[9].CookedValue)/1024
$ImagingReceived = ($Counters[1].CounterSamples[10].CookedValue - $Counters[0].CounterSamples[10].CookedValue)/1024
$ImagingSent = ($Counters[1].CounterSamples[11].CookedValue - $Counters[0].CounterSamples[11].CookedValue)/1024
$RTAVReceived = ($Counters[1].CounterSamples[12].CookedValue - $Counters[0].CounterSamples[12].CookedValue)/1024
$RTAVSent = ($Counters[1].CounterSamples[13].CookedValue - $Counters[0].CounterSamples[13].CookedValue)/1024
$SerialReceived = ($Counters[1].CounterSamples[14].CookedValue - $Counters[0].CounterSamples[14].CookedValue)/1024
$SerialSent = ($Counters[1].CounterSamples[15].CookedValue - $Counters[0].CounterSamples[15].CookedValue)/1024
$Bandwidth = ($Counters[1].CounterSamples[16].CookedValue + $Counters[0].CounterSamples[16].CookedValue)/2
$Jitter = ($Counters[1].CounterSamples[17].CookedValue + $Counters[0].CounterSamples[17].CookedValue)/2
$PacketLoss = ($Counters[1].CounterSamples[18].CookedValue + $Counters[0].CounterSamples[18].CookedValue)/2
$RTT = ($Counters[1].CounterSamples[19].CookedValue + $Counters[0].CounterSamples[19].CookedValue)/2


Write-Output "__________________________________________________________________________"
Write-Output "Average Download Bandwidth for session: .::$sessionname::."
Write-Output "--------------------------------------------------------------------------"
$rounded = [math]::Round($AudioReceived/($SampleInterval*($Samples-1)))
Write-Output "Audio (Received)`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($AudioSent/($SampleInterval*($Samples-1)))
Write-Output "Audio (Sent)`t`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($CDRReceived/($SampleInterval*($Samples-1)))
Write-Output "Client Drive Redirection (Received)`t $rounded kbps"
$rounded = [math]::Round($CDRSent/($SampleInterval*($Samples-1)))
Write-Output "Client Drive Redirection (Sent)`t`t $rounded kbps"
$rounded = [math]::Round($ClipboardReceived/($SampleInterval*($Samples-1)))
Write-Output "Clipboard (Received)`t`t`t`t $rounded kbps"
$rounded = [math]::Round($ClipboardSent/($SampleInterval*($Samples-1)))
Write-Output "Clipboard (Sent)`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($HTML5MMRReceived/($SampleInterval*($Samples-1)))
Write-Output "HTML5 Redirection (Received)`t`t $rounded kbps"
$rounded = [math]::Round($HTML5MMRSent/($SampleInterval*($Samples-1)))
Write-Output "HTML5 Redirection (Sent)`t`t`t $rounded kbps"
$rounded = [math]::Round($ImagingReceived/($SampleInterval*($Samples-1)))
Write-Output "Imaging (Received)`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($ImagingSent/($SampleInterval*($Samples-1)))
Write-Output "Imaging (Sent)`t`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($RTAVReceived/($SampleInterval*($Samples-1)))
Write-Output "Real-Time AV (Received)`t`t`t`t $rounded kbps"
$rounded = [math]::Round($RTAVSent/($SampleInterval*($Samples-1)))
Write-Output "Real-Time AV (Sent)`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($SerialReceived/($SampleInterval*($Samples-1)))
Write-Output "Serial Port / Scanner (Received)`t $rounded kbps"
$rounded = [math]::Round($SerialSent/($SampleInterval*($Samples-1)))
Write-Output "Serial Port / Scanner (Sent)`t`t $rounded kbps"
Write-Output "---------------------Total Bandwidth--------------------------------------"
$rounded = [math]::Round($TotalReceived/($SampleInterval*($Samples-1)))
Write-Output "Session Bandwidth (Received)`t`t $rounded kbps"
$rounded = [math]::Round($TotalSent/($SampleInterval*($Samples-1)))
Write-Output "Session Bandwidth (Sent)`t`t`t $rounded kbps"
$rounded = [math]::Round($Bandwidth)
Write-Output "Available Bandwidth`t`t`t`t`t $rounded kbps"
$rounded = [math]::Round($RTT)
Write-Output "RTT`t`t`t`t`t`t`t`t`t $rounded ms"
$rounded = [math]::Round($Jitter)
Write-Output "Jitter`t`t`t`t`t`t`t`t $rounded ms"
$rounded = [math]::Round($PacketLoss)
Write-Output "Packet Loss`t`t`t`t`t`t`t $rounded%"