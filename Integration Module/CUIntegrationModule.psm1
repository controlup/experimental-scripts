#Requires -version 3


function New-CUSBAConfigItem([string] $component)
{
    if (-not(Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component))
    {
        $result = New-Item -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\ -Name $component
    }
    else {
        $result = "There is already a configuration for $component"
    }
    return $result
}

function Get-CUSBAConfigItem([string] $component)
{
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component)
    {
        $result = Get-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component
    }
    else 
    {
        $result = "There is no configuration for $component"
    }
    return $result
    
}

function Remove-CUSBAConfigItem([string] $component)
{
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component)
    {
        $result = Remove-Item -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component -Force
    }
    else {
        $result = "There is no configuration for $component"
    }
    return $result
}

function Set-CUSBAConfigItemValue([string] $component, [string] $Parameter, [string] $value)
{
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component)
    {
        $result = Set-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component -Name $Parameter -Value $value
    }
    else {
        $result = "There is no configuration item for $component, you first need to create it using New-CUSBAConfigItem"
    }
    return $result
}

function Remove-CUSBAConfigItemValue([string] $component, [string] $Parameter)
{
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component)
    {
        $result = Remove-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component -Name $Parameter
    }
    return $result
}

function Get-CUSBAConfigItemValue([string] $component, [string] $Parameter)
{
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component)
    {
        $result = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$component -Name $Parameter
    }
    else {
        $result = "There is no configuration item for $component, you first need to create it using New-CUSBAConfigItem"
    }
    return $result
}

function New-CUServiceNowIncident([string] $component, [string] $AssignmentGroup, [string] $ShortDescription, [string] $CallerId, [string] $CmdbCi, [string] $Description)
{
    $fqdn = Get-CUSBAConfigItemValue -component $component -Parameter FQDN
    $user = Get-CUSBAConfigItemValue -component $component -Parameter User
    $pass = Get-CUSBAConfigItemValue -component $component -Parameter Password
    
    $JsonDescription = ($Description | Out-String | ConvertTo-Json)
    $body = "{ 'assignment_group':'$AssignmentGroup','short_description':'$ShortDescription', 'caller_id':'$CallerId', 'cmdb_ci':'$CmdbCi', 'description':$JsonDescription}"
    
    # Build auth header
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))

    # Set proper headers
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))
    
    # Specify endpoint uri
        $uri = "https://$fqdn/api/now/table/incident"
    # Specify HTTP method
        $method = "post"


    # Ignore invalid SSL Cert
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    # https://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error

    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    # New API Call
    $response = Invoke-RestMethod -Headers $headers -ContentType "application/json" -Method $method -Uri $uri -Body $body 

    return $response.result
}

function New-CUSlackMessage([string] $component, [string] $UserName, [string] $Title, [string] $Message, [string] $Message2, [string] $Button_Text, [string] $Button_Url)
{
    $WebhookUrl = Get-CUSBAConfigItemValue -component $component -Parameter URL

    $slackbody = @"
    {
            "username": "$UserName",
            "icon_emoji":":controlup:",
    	    "blocks": [
		    {
			    "type": "section",
			    "text": {
				    "type": "mrkdwn",
				    "text": "$Title"
			    }
		    },
		    {
			    "type": "divider"
		    },
		    {
			    "type": "section",
			    "text": {
				    "type": "mrkdwn",
				    "text": "$Message"
			    }
		    },
		    {
			    "type": "section",
			    "text": {
				    "type": "mrkdwn",
				    "text": "$Message2"
			    },
			    "accessory": {
				    "type": "button",
				    "text": {
					    "type": "plain_text",
					    "text": "$Button_Text",
					    "emoji": true
				    },
				    "url":	"$Button_Url"
			    }
		    },
		    {
			    "type": "divider"
		    }
	    ]
    }
"@

    # This section will send the API call using Powershell to Slack and Slack will process the request and send the notification
    Invoke-RestMethod -uri $WebhookUrl -Method Post -body $slackbody -ContentType 'application/json'
}

function New-CUTeamsMessage([string] $component, [string] $summary, [string] $activityTitle, [string] $activitySubtitle, [string] $CITypeName, [string] $CIName, [string] $IssueType, [string] $Issue, [string] $NextStepType, [string] $NextStep, [string] $OpenUriName, [string] $OpenUri)
{   
    $TeamsIncomingWebhookUri = Get-CUSBAConfigItemValue -component $component -Parameter URL
    $teamsbody = @"
    {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "FF0000",
        "summary": "$summary",
        "sections": [{
            "activityTitle": "$activityTitle",
            "activitySubtitle": "$activitySubtitle",
            "facts": [{
                "name": "$CITypeName",
                "value": "$CIName"
            }, {
                "name": "$IssueType",
                "value": "$Issue"
            }, {
                "name": "$NextStepType",
                "value": "$NextStep"
            }],
            "markdown": true
        }],
    "potentialAction": [
        {
        "@type": "OpenUri",
        "name": "$OpenUriName",
        "targets": [
            { "os": "default", "uri": "$OpenUri" }
        ]
        }
    ]
    }
"@
    write-output $teamsbody
    # This section will send the API call using Powershell to Slack and Slack will process the request and send the notification
    Invoke-RestMethod -uri $TeamsIncomingWebhookUri -Method Post -body $teamsbody -ContentType 'application/json'

}

