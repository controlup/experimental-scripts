Function Get-WinEventData {
<#
.SYNOPSIS
    Get custom event data from an event log record

.DESCRIPTION
    Get custom event data from an event log record

    Takes in Event Log entries from Get-WinEvent, converts each to XML, extracts all properties from Event.EventData.Data

    Notes:
        To avoid overwriting existing properties or skipping event data properties, we append 'EventData' to these extracted properties
        Some events store custom data in other XML nodes.  For example, AppLocker uses Event.UserData.RuleAndFileData

.PARAMETER Event
    One or more event.
    
    Accepts data from Get-WinEvent or any System.Diagnostics.Eventing.Reader.EventLogRecord object

.INPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

.OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

.EXAMPLE
    Get-WinEvent -LogName system -max 1 | Get-WinEventData | Select -Property MachineName, TimeCreated, EventData*

    #  Simple example showing the computer an event was generated on, the time, and any custom event data

.EXAMPLE
    Get-WinEvent -ComputerName DomainController1 -FilterHashtable @{Logname='security';id=4740} -MaxEvents 10 | Get-WinEventData | Select TimeCreated, EventDataTargetUserName, EventDataTargetDomainName

    #  Find lockout events on a domain controller
    #    ideally you have log forwarding, audit collection services, or a product from a t-shirt company for this...

.NOTES
    Concept and most code borrowed from Ashley McGlone
        http://blogs.technet.com/b/ashleymcglone/archive/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs.aspx

.FUNCTIONALITY
    Computers
#>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0 )]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $event
    )

    Process
    {
        #Loop through provided events
        foreach($entry in $event)
        {
            #Get the XML...
            $XML = [xml]$entry.ToXml()
        
            #Some events use other nodes, like 'UserData' on Applocker events...
            $XMLData = $null
            if( $XMLData = @( $XML.Event.EventData.Data ) )
            {
                For( $i=0; $i -lt $XMLData.count; $i++ )
                {
                    #We don't want to overwrite properties that might be on the original object, or in another event node.
                    Add-Member -InputObject $entry -MemberType NoteProperty -name "EventData$($XMLData[$i].name)" -Value $XMLData[$i].'#text' -Force
                }
            }

            $entry
        }
    }
}

#Set Timing
$starttime = (Get-Date)
# Replace with Argument
$seconds = "20"
$endtime = (Get-Date).AddSeconds($seconds)

# Enable Auditing for Firewall
# To-do: add logic that checks current state so it will skip disabling this at the end
auditpol.exe /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable
auditpol.exe /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable

# Script execution pauses to e.g. launch the app and test things while events are being written to the event viewer
# The next line is for future enhancement that allows you to enter an application to launch in the session (by argument)
# $application = "c:\program files\whatever.exe"
Start-Sleep -Second $seconds

# Get data from Event Viewer based on timing above and use the Get-WinEventData function to parse the results
# Blocked packets, connections and port bind for Inbound connections
$blockinbound = Get-WinEvent -FilterHashtable @{logname='security';id=5031,5150,5151,5152,5153,5155,5157,5159;StartTime=$starttime;EndTime=$endtime} | Get-WinEventData | Where-Object{($_.EventDataDirection -eq "%%14592") -and ($_.EventDataApplication -notlike "*svchost*" -and $_.EventDataApplication -notlike "System")} | Select TimeCreated, EventDataApplication, EventDataSourcePort, EventDataDestPort
# Blocked packets, connections and port bind for Outbound connections
$blockoutbound = Get-WinEvent -FilterHashtable @{logname='security';id=5031,5150,5151,5152,5153,5155,5157,5159;StartTime=$starttime;EndTime=$endtime} | Get-WinEventData | Where-Object{($_.EventDataDirection -eq "%%14593") -and ($_.EventDataApplication -notlike "*svchost*" -and $_.EventDataApplication -notlike "System")} | Select TimeCreated, EventDataApplication, EventDataSourcePort, EventDataDestPort
# Allowed packets, connections and port bind for Inbound connections
$allowinbound = Get-WinEvent -FilterHashtable @{logname='security';id=5154,5156,5158;StartTime=$starttime;EndTime=$endtime} | Get-WinEventData | Where-Object{($_.EventDataDirection -eq "%%14592") -and ($_.EventDataApplication -notlike "*svchost*" -and $_.EventDataApplication -notlike "System")} | Select TimeCreated, EventDataApplication, EventDataSourcePort, EventDataDestPort
# Blocked packets, connections and port bind for Outbound connections
$allowoutbound = Get-WinEvent -FilterHashtable @{logname='security';id=5154,5156,5158;StartTime=$starttime;EndTime=$endtime} | Get-WinEventData | Where-Object{($_.EventDataDirection -eq "%%14593") -and ($_.EventDataApplication -notlike "*svchost*" -and $_.EventDataApplication -notlike "System")} | Select TimeCreated, EventDataApplication, EventDataSourcePort, EventDataDestPort

# Disable Auditing for Firewall
auditpol.exe /set /subcategory:"Filtering Platform Packet Drop" /success:disable /failure:disable
auditpol.exe /set /subcategory:"Filtering Platform Connection" /success:disable /failure:disable

$blockinbound
$blockoutbound
$allowinbound
$allowoutbound