#Requires -version 3
  
<#
.SYNOPSIS
    ControlUp Integration PowerShell Module
.DESCRIPTION
    This module allows ControlUp users to integrate with different other solutions (ServiceNow, Teams, Slack...). It's suggested to deploy it on each ControlUp Monitor server.
.CONTEXT
    ControlUp
.MODIFICATION_HISTORY
    Samuel Legrand - 14/08/20 - Original code
    Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    Samuel Legrand - 18/08/20 - Remove debug output on New-CUTeamsMessage
    Samuel Legrand - 19/08/20 - Update the password management for Component and change it for New-CUServiceNowIncident
.LINK
    
.COMPONENT
    Technical functions (Needed for the configuration of the PowerShell module:
        New-CUSBAConfigItem - This function creates a ConfigItem in order to store configuration for a "Component"
        Get-CUSBAConfigItem - This function return the stored configuration for a "Component"
        Remove-CUSBAConfigItem - This function removes a ConfigItem (and all the configuration for a "Component")
        Set-CUSBAConfigItemValue - This function sets a paramater value for a specific "Component"
        Remove-CUSBAConfigItemValue - This function removes a parameter value for a specific "Component"
        Get-CUSBAConfigItemValue - This function returns the value of a parameter for a specific "Component"
        Get-CUSBAConfigItemCredentials - This function returns the Credentials for a specific "Component"
        Set-CUSBAConfigItemCredentials - This function sets the Credentials for a specific "Component"
        
    Integration functions (Used to integrate with other solutions)
        New-CUServiceNowIncident - This function creates a Service Now Incident
        New-CUSlackMessage - This function creates a Slack message
        New-CUTeamsMessage - This function creates a Teams message

.NOTES
    Version:        1.2
    Author:         Samuel Legrand
    Creation Date:  2020-08-14
    Updated:        2020-08-18
                    Remove debug output on New-CUTeamsMessage
                    2020-08-19
                    Update the password management for Component and change it for New-CUServiceNowIncident
    Purpose:        Script Based Action, created for ControlUp Monitoring
        
    Copyright (c) All rights reserved.
#>

function New-CUSBAConfigItem()
{
    <#
    .SYNOPSIS
        Creates a ConfigItem in order to store configuration for a "Component"
    .DESCRIPTION
        Creates a ConfigItem in order to store configuration for a "Component" inside the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        New-CUSBAConfigItem -component Teams
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to create'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component
    )
    if (-not(Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component))
    {
        $result = New-Item -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\ -Name $Component
    }
    else {
        $result = "There is already a configuration for $Component"
    }
    return $result
}

function Get-CUSBAConfigItem()
{
    <#
    .SYNOPSIS
        Returns the stored configuration for a "Component"
    .DESCRIPTION
        Returns the stored configuration for a "Component" from the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Get-CUSBAConfigItem -component Teams
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to retrieve the configuration'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $result = Get-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component
    }
    else 
    {
        $result = "There is no configuration for $Component"
    }
    return $result
    
}

function Remove-CUSBAConfigItem()
{
    <#
    .SYNOPSIS
        Removes the stored configuration for a "Component"
    .DESCRIPTION
        Removes the stored configuration for a "Component" from the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Remove-CUSBAConfigItem -component Teams
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to remove the configuration'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $result = Remove-Item -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Force
    }
    else {
        $result = "There is no configuration for $Component"
    }
    return $result
}

function Set-CUSBAConfigItemValue()
{
    <#
    .SYNOPSIS
        Sets a paramater value for a specific "Component"
    .DESCRIPTION
        Sets a paramater value for a specific "Component" in the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Set-CUSBAConfigItemValue -Component Teams -Parameter URL -Value "https://outlook.office.com/webhook/9f42e6b7-7ef7-427e-a033-bb304bba2dbd@2f691474-7166-4c4b-967d-672ed261d99b/IncomingWebhook/588bf3d425a74781bc439eeaf2b4d4f8/13dcb3eb-3d9d-46e7-8fdf-a0bf790ff288"
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to set a value'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the parameter'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Parameter,
        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter the value you want to store'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Value
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $result = Set-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Name $Parameter -Value $Value
    }
    else {
        $result = "There is no configuration item for $Component, you first need to create it using New-CUSBAConfigItem"
    }
    return $result
}

function Remove-CUSBAConfigItemValue()
{
    <#
    .SYNOPSIS
        Sets a paramater value for a specific "Component"
    .DESCRIPTION
        Sets a paramater value for a specific "Component" in the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Remove-CUSBAConfigItemValue -Component Teams -Parameter URL
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to remove a value'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the parameter'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Parameter
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $result = Remove-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Name $Parameter
    }
    return $result
}

function Get-CUSBAConfigItemValue()
{
    <#
    .SYNOPSIS
        Returns the value of a parameter for a specific "Component"
    .DESCRIPTION
        Returns the value of a parameter for a specific "Component" from the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Get-CUSBAConfigItemValue -Component Teams -Parameter URL
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to get a value'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the parameter'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Parameter
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $result = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Name $Parameter
    }
    else {
        $result = "There is no configuration item for $Component, you first need to create it using New-CUSBAConfigItem"
    }
    return $result
}

function Set-CUSBAConfigItemCredentials()
{
    <#
    .SYNOPSIS
        Set Credentials for a specific "Component"
    .DESCRIPTION
        Set Credentials for a specific "Component" into the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Set-CUSBAConfigItemCredentials -Component ServiceNow -Parameter Credentials
    .MODIFICATION_HISTORY
        Samuel Legrand - 19/08/20 - Original code
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-19
        Updated:        

        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to set credentials'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the parameter'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Parameter
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $PSCred = Get-Credential
        $PSCred | Export-Clixml -Path $ENV:TEMP\temp.xml
        $Value = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($(get-content $ENV:TEMP\temp.xml)))
        $result = Set-ItemProperty -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Name $Parameter -Value $Value
    }
    else {
        $result = "There is no configuration item for $Component, you first need to create it using New-CUSBAConfigItem"
    }
    return $result
}

function Get-CUSBAConfigItemCredentials()
{
    <#
    .SYNOPSIS
        Get Credentials for a specific "Component"
    .DESCRIPTION
        Get Credentials for a specific "Component" from the registry of a ControlUp Monitor
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        Get-CUSBAConfigItemCredentials -Component ServiceNow -Parameter Credentials
    .MODIFICATION_HISTORY
        Samuel Legrand - 19/08/20 - Original code
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-19
        Updated:        

        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to get credentials'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the parameter'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Parameter
    )
    if (Test-Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component)
    {
        $value = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Smart-X\ControlUp\SBASettings\$Component -Name $Parameter
        $Content = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($value))
        $content |out-file $ENV:TEMP\temp.xml -Force
        $result = Import-Clixml $env:temp\temp.xml
    }
    else {
        $result = "There is no configuration item for $Component"
    }
    return $result
}

function New-CUServiceNowIncident()
{
    <#
    .SYNOPSIS
        Creates a Service Now Incident
    .DESCRIPTION
        Creates a Service Now Incident using the SNow REST API
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        New-CUServiceNowIncident -Component ServiceNowProd -AssignmentGroup "Citrix Admins" -ShortDescription "Important error with user X" -CallerId "Username" -CmdbCi "Machinename" -Description "A longer description of the incident!"
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.1
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
                        2020-08-19
                        Change the password management to a PSCredentials object
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to use'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Service Now assignment group name'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $AssignmentGroup,
        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter a short description for your Service Now incident'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ShortDescription,
        [Parameter(
            Position=3, 
            Mandatory=$true, 
            HelpMessage='Enter the username of the Service Now incident caller'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $CallerId, 
        [Parameter(
            Position=4, 
            Mandatory=$true, 
            HelpMessage='Enter the affected CI object'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $CmdbCi,
        [Parameter(
            Position=5, 
            Mandatory=$true, 
            HelpMessage='Enter the Service Now full description of the incident'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Description
    )
    $fqdn = Get-CUSBAConfigItemValue -component $Component -Parameter FQDN
    $credential = Get-CUSBAConfigItemCredentials -Component $Component -Parameter Credentials
    $user = $credential.GetNetworkCredential().username
    $pass = $credential.GetNetworkCredential().password
    
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

function New-CUSlackMessage()
{
    <#
    .SYNOPSIS
        Creates a Slack message
    .DESCRIPTION
        Creates a Slack message using an Incoming Webhook
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        New-CUSlackMessage -Component SlackIncidentChannel -UserName "Toto" -Title "Title" -Message "Message1" -Message2 "Message2" -Button_Text "Click Here!" -Button_Url "https://www.controlup.com"
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to use'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Component, 
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the author of your Slack message'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $UserName, 
        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter a title for your Slack message'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Title,
        [Parameter(
            Position=3, 
            Mandatory=$true, 
            HelpMessage='Enter the body of the first part of the Slack message'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [Parameter(
            Position=4, 
            Mandatory=$true, 
            HelpMessage='Enter the body of the second part of the Slack message'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $Message2,
        [Parameter(
            Position=5, 
            Mandatory=$false, 
            HelpMessage='Enter the text for the button of the Slack message'
        )]
        [string] $Button_Text, 
        [Parameter(
            Position=6, 
            Mandatory=$false, 
            HelpMessage='Enter the link for the button of the Slack message'
        )]
        [string] $Button_Url
    )
    $WebhookUrl = Get-CUSBAConfigItemValue -component $Component -Parameter URL

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

function New-CUTeamsMessage()
{   
    <#
    .SYNOPSIS
        Creates a Teams message
    .DESCRIPTION
        Creates a Slack message using a Incoming Webhook
    .CONTEXT
        ControlUp Monitor Server
    .EXAMPLE
        New-CUTeamsMessage -component Teams -activityTitle Title -activitySubtitle SubTitle -OpenUriName ControlUp -OpenUri https://www.controlup.com
    .MODIFICATION_HISTORY
        Samuel Legrand - 14/08/20 - Original code
        Samuel Legrand - 14/08/20 - Standardizing script, based on the ControlUp Scripting Standards (version 0.2)
    .LINK
        
    .COMPONENT
        
    .NOTES
        Version:        1.0
        Author:         Samuel Legrand
        Creation Date:  2020-08-14
        Updated:        2020-08-14
                        Standardized the function, based on the ControlUp Standards (v1.0)
        Purpose:        Script Based Action, created for ControlUp Monitoring
            
        Copyright (c) All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the name of the component you want to use'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $component,
        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter a title for your Teams message'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $activityTitle,
        [Parameter(
            Position=2, 
            Mandatory=$false, 
            HelpMessage='Enter a subtitle for your Teams message'
        )]
        [string] $activitySubtitle,
        [Parameter(
            Position=3, 
            Mandatory=$false, 
            HelpMessage='Enter the text of the optional button'
        )]
        [string] $OpenUriName, 
        [Parameter(
            Position=4, 
            Mandatory=$false, 
            HelpMessage='Enter the Uri of the optional button'
        )]
        [string] $OpenUri
    )
    $TeamsIncomingWebhookUri = Get-CUSBAConfigItemValue -component $component -Parameter URL
    $teamsbody = @"
    {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "FF0000",
        "summary": "Summary",
        "sections": [{
            "activityTitle": "$activityTitle",
            "activitySubtitle": "$activitySubtitle",
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
    # This section will send the API call using Powershell to Slack and Slack will process the request and send the notification
    Invoke-RestMethod -uri $TeamsIncomingWebhookUri -Method Post -body $teamsbody -ContentType 'application/json'

}

