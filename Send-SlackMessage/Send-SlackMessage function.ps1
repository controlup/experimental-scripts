function Send-SlackMessage {
    param(
        $message
    )
    $webhookURL = "<URL>"

    # Webhooks Channel
    $ChannelName = "#<CHANNEL>"

    $BodyTemplate = @"
    {
        "channel": "CHANNELNAME",
        "username": "CUEMEA HouseBot",
        "text": "MESSAGEHERE",
    }
"@

    $BodyTemplate = $BodyTemplate.Replace("MESSAGEHERE",$message).Replace("CHANNELNAME","$ChannelName")
    Invoke-RestMethod -uri $webhookURL -Method Post -body $BodyTemplate -ContentType 'application/json'
}