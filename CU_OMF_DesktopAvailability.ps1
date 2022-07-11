$ddc = "CUXENDDC01"

$dgs = @{}
#Deliver group name - threshold
$dgs["Windows 10 VDI"] = 25
$dgs["AppServers"] = 51
$dgs["Server 2016 Bot DG"] = 49

$eventLogName = "ControlUp Low DesktopsAvailable Triggers"
$threshold = 1
$timeframe = 1 ##hours

$exists = [System.Diagnostics.EventLog]::SourceExists($eventLogName);
if(-not $exists)
{
    New-EventLog -LogName "Application" -Source $eventLogName -erroraction stop
}

$DebugPreference = [System.Management.Automation.ActionPreference]::Continue

if( ! (  Import-Module -Name Citrix.DelegatedAdmin.Commands -ErrorAction SilentlyContinue -PassThru -Verbose:$false) `
    -and ! ( Add-PSSnapin -Name Citrix.Broker.Admin.* -ErrorAction SilentlyContinue -PassThru -Verbose:$false) )
{
    $errorMessage = 'Failed to load Citrix PowerShell cmdlets - is this a Delivery Controller or have Studio or the PowerShell SDK installed ?'    
    Throw $errorMessage
}

$DGData = Get-BrokerDesktopGroup -AdminAddress $ddc | select name,desktopsavailable,totaldesktops,@{l="percentage";e={$_.desktopsavailable/$_.totaldesktops*100}},uid | Group-Object -Property name -AsHashTable

if($DGData -eq $null)
{
    write-host "Did not find delivery groups"
    write-host "Returning"
    return
}
Write-Debug "$(get-date) got $($dgdata.values.count) results"

foreach($dg in $dgs.keys)
{
    Write-Debug "$(get-date) Checking $dg"
    if($DGData[$dg] -eq $null)
    {
        write-host "Did not find delivery group $dg"
        write-host "Returning"
        return
    }    

    Write-Debug "$(get-date) Checking if $($DGData[$dg].percentage) is lower than $($dgs[$dg])"
    if($DGData[$dg].percentage -le $dgs[$dg])
    {
        ##check how many events have been logged
        $filterhash = @{logname="application";providername=$eventLogName;id=$DGData[$dg].uid;starttime=([datetime]::Now.AddHours(-$timeframe))}
        Write-Debug "$(get-date) Registry search: $([string]::Join("; ",($filterhash.GetEnumerator() | ForEach-Object {"$($_.key)=$($_.value)"})))"
        [array]$number = Get-WinEvent -FilterHashtable $filterhash -ErrorAction SilentlyContinue
        if($number.count -lt $threshold)
        {
            Write-Debug "FOLLOW UP ACTION for $DG - $($DGData[$dg])"
            Write-EventLog -LogName Application -Source $eventLogName -EntryType Warning -Message "Delivery group $dg has an available desktop percentage of $($DGData[$dg].percentage)% ($($DGData[$dg].DesktopsAvailable) out of $($DGData[$dg].TotalDesktops)). Threshold crossed is $($dgs[$dg])%" -EventId $DGData[$dg].uid
        } else
        {
            Write-Debug "Ignoring $DG - $($DGData[$dg]) - found event in recent past"
        }
    }
}