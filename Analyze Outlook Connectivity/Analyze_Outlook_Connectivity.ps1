<#
    .SYNOPSIS
        Analyze Outlook Connectivity

    .DESCRIPTION
        Analyze Outlook Connectivity

    .EXAMPLE
        . .\Analyze_Outlook_Connectivity.ps1 -OutlookPID 12345 
        Analyze the outlook connectivity for the process 12345

    .CONTEXT
        Session

    .MODIFICATION_HISTORY
        Created  SLE : 2021-05-23
  
    AUTHOR: Samuel Legrand
#>
[CmdLetBinding()]
Param (
    [Parameter(Mandatory=$true,HelpMessage='Enter the Outlook process ID')][ValidateNotNullOrEmpty()]                             [int]$OutlookPID
)


Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
###$VerbosePreference = "continue" # better invoked by passing the Debug parameter:  -verbose

Try {
    $Process = Get-Process -Id $OutlookPID 
}
Catch {
    throw "PID $OutlookPID is not running!"
}

if (-not ($Process.Name -ilike "outlook")){
    throw "The provided PID ($OutlookPid) is not an Outlook process ($($Process.Name))!"
}

# Initializing an Outlook Application COM Object:
try {
    $Outlook = New-Object -ComObject Outlook.Application
    [System.Uri]$ExchangeMailboxURL = $outlook.Session.ExchangeMailboxServerName
}
Catch{
    throw "Unable to retrieve the URL of the Exchange Mailbox"
}

Write-Output "Exchange Mailbox URL: $ExchangeMailboxURL"
Write-Output "FQDN: $($ExchangeMailboxURL.DnsSafeHost)"

switch ($Outlook.Session.ExchangeConnectionMode) {
    0 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olNoExchange - The account does not use an Exchange server." }
    600 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olCachedConnectedDrizzle - The account is using cached Exchange mode such that headers are downloaded first, followed by the bodies and attachments of full items." }
    700 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olCachedConnectedFull - The account is using cached Exchange mode on a Local Area Network or a fast connection with the Exchange server. The user can also select this state manually, disabling auto-detect logic and always downloading full items regardless of connection speed." }
    500 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olCachedConnectedHeaders - The account is using cached Exchange mode on a dial-up or slow connection with the Exchange server, such that only headers are downloaded. Full item bodies and attachments remain on the server. The user can also select this state manually regardless of connection speed." }
    400 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olCachedDisconnected - The account is using cached Exchange mode with a disconnected connection to the Exchange server." }
    200 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olCachedOffline - The account is using cached Exchange mode and the user has selected Work Offline from the File menu." }
    300 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olDisconnected - The account has a disconnected connection to the Exchange server." }
    100 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olOffline - The account is not connected to an Exchange server and is in the classic offline mode. This also occurs when the user selects Work Offline from the File menu." }
    800 {  Write-Output "Exchange Connection Mode: $($Outlook.Session.ExchangeConnectionMode)/olOnline - The account is connected to an Exchange server and is in the classic online mode." }
    
    Default {throw "Exchange Connection Mode unknown / not supported"}
}

