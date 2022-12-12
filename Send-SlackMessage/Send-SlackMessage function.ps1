function Send-SlackMessage {
    param(
        $message
    )
    $webhookURL = "https://hooks.slack.com/services/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"

    # Webhooks Channel
    $ChannelName = "#cuemea-status-and-messages"

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