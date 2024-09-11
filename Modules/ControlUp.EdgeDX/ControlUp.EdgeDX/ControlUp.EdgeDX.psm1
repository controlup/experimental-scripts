### Functions #Start

#
# module internal variables
$script:EDXTenant = $null
$script:EDXAPIKey = $null
$script:EDXDeviceToken = $null
$script:LogfilePath = $null
$script:LogToConsole = $true

$script:SecureSecretStoreFile = Join-Path -Path $env:APPDATA -ChildPath "EdgeDX_$env:COMPUTERNAME.xml"
$script:SecureSecretStoreFile = Join-Path -Path $env:LOCALAPPDATA -ChildPath "EdgeDX_$env:COMPUTERNAME.xml"

<#
.Synopsis
   Sets the APIKey and/or Device token
.DESCRIPTION
   Sets the APIKey and/or Device token for the duration of the powershell session (or until overwritten).
   This avoids the need to specify authorization on every call, which may improve readability / maintainability
.PARAMETER Tenant
   The EdgeDX tenant name
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
.PARAMETER DeviceToken
   API calls associated with a device require require a device access token for their operation. Device access tokens are associated with devices (endpoints)
   and have a fixed set of permissions. A device token is required for API calls to /api/device (but not /api/devices) 
.LINK
   Details of API calls are available at https://apidoc.sip.controlup.com
#>
function Set-EDXSessionAuthorization {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $false,ValueFromPipelineByPropertyName = $true)][string]$Tenant,
        [parameter(mandatory = $false,ValueFromPipelineByPropertyName = $true)][string]$APIKey,
        [parameter(mandatory = $false,ValueFromPipelineByPropertyName = $true)][string]$DeviceAccessToken
    )
    if (-not [string]::IsNullOrWhiteSpace($Tenant)) {
        $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''
        $script:EDXTenant = $Tenant
    }
    if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
        $script:EDXAPIKey = $APIKey
    }
    if (-not [string]::IsNullOrWhiteSpace($DeviceAccessToken)) {
        $script:EDXDeviceToken = $DeviceAccessToken
    }
}

Export-ModuleMember Set-EDXSessionAuthorization

<#
.Synopsis
   Sets the Logfile path and enables/disables logging to console
.DESCRIPTION
   The Logfile is used to record significant events from the EdgeAPIFunction module. 
   If no log file path is specified via this call, a path will be generated dynamically and reported via Write-Host
.PARAMETER LogfilePath
   The Logfile path. If it does not exist, it will be created. If it already exists, new entries will be appended 
.PARAMETER LogToConsole
   If set, will control the logging to console, as well as to file
#>
function Set-EDXLogfilePath {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$LogfilePath,
        [parameter(mandatory = $false)][bool]$LogToConsole
    )
    $script:LogfilePath = $LogfilePath
    if ($LogToConsole -ne $null) {
        $script:LogToConsole = $LogToConsole
    }
}

Export-ModuleMember Set-EDXLogfilePath

<#
.Synopsis
   Converts a powershell [datetime] object to the format required for a filter parameter
.DESCRIPTION
   Filters use ISO 8601 formatted dates, using the 'O' format e.g. 2024-07-07T12:54:34.5410481+01:00
.PARAMETER DateTime
   A datetime object to be converted. UTC and local time formats work.
.LINK
   https://learn.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings
#>
function ConvertTo-EDXDateTime {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][datetime]$DateTime
    )
    #$DateTime.ToUniversalTime().ToString('O') # -replace "(?<=\.\d\d\d)(\d+Z)",'Z'   # remove decimal places after the last 3
    $DateTime.ToString('O')
}

Export-ModuleMember ConvertTo-EDXDateTime

<#
.Synopsis
   Sets the console width
.DESCRIPTION
   Setting the width to 400 or more may assist the presentation of tabular data (e.g. using Format-Table). 
.PARAMETER OutputWidth
   The output buffer width, in fixed-width characters.
#>
Function Set-OutBufferSize {
    [CmdletBinding()]
    param (
        # Altering the size of the PS Buffer
        [parameter(mandatory = $false)][int]$OutputWidth = 400
    )
    $PSWindow = (Get-Host).UI.RawUI
    $WideDimensions = $PSWindow.BufferSize
    $WideDimensions.Width = $OutputWidth
    $PSWindow.BufferSize = $WideDimensions
}

Export-ModuleMember Set-OutBufferSize

<#
.Synopsis
   Sets the supported SSL/TLS protocols for the session
.DESCRIPTION
   Set the supported TLS protocols to Weak (allows any protocols, including deprecated protocols) or Strong (only permits TLS1.2 and higher)
.PARAMETER TLSLevel
   Set to 'Weak' or 'Strong'
.NOTES
   If you use deprecated protocols, your data may be at risk.
.LINK
   See https://learn.microsoft.com/en-us/dotnet/framework/network-programming/tls 
#>
Function Set-EDXTLSSupport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,HelpMessage='TLS level')][ValidateSet('Weak','Strong')][string]$TLSLevel = 'Strong'
    )
    if ($TLSLevel -eq 'Strong') {
        $SupportedProtocols = [System.Enum]::GetNames([System.Net.SecurityProtocolType])
        if ('Tls13' -in $SupportedProtocols) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13   # use TLS 1.3 if available
        }
        else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12       # use at least TLS 1.2
        }
    }
    else {
        # Setup TLS Setup
        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    }
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

Export-ModuleMember Set-EDXTLSSupport

<#
.Synopsis
   Sets the proxy address for the session
.DESCRIPTION
   Set the Proxy address - required in some environments to allow powershell to gain internet access
.PARAMETER Proxy
   Set to the address of the environment's proxy server
#>
Function Set-EDXProxy {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$Proxy
    )
    # Setup Proxy
    [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($Proxy)
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
}

Export-ModuleMember Set-EDXProxy

<#
.Synopsis
   Writes a log message for the session
.DESCRIPTION
   Writes a log message to the logfile specified by Set-EDXLogfilePath.
   If no log file path is specified via Set-EDXLogfilePath, a path will be generated dynamically and reported via Write-Host.
   The path will be derived from the name of the script which called into the module.
.PARAMETER Message
   Text of message to be logged
.PARAMETER DontUseWriteHost
   Forces the script to use Write-Output, rather than Write-Host
#>
Function Write-EDXLog {
    [CmdletBinding()]
    Param (
        [Parameter(mandatory = $true,ValueFromPipeline)][string]$Message,
        [parameter(mandatory = $false)][switch]$DontUseWriteHost
    )

    Process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $Message"

        # Append the log entry to the specified file
        if ([string]::IsNullOrWhiteSpace($script:LogfilePath)) {
            $CurrentFile = $null
            Get-PSCallStack | ForEach-Object {
                $Context = $_
                if ([string]::IsNullOrWhiteSpace($CurrentFile)) {
                    $CurrentFile = $Context.ScriptName
                }
                elseif ([string]::IsNullOrWhiteSpace($script:LogfilePath) -and ($CurrentFile -ne $Context.ScriptName)) {
                    $script:LogfilePath = $Context.ScriptName -replace "\.ps1$",".log"
                    Write-Host -ForegroundColor Green "LogfilePath set to $script:LogfilePath"
                }
            }
        }
        Add-Content -Path $script:LogfilePath -Value $logEntry

        If (-not $script:LogToConsole){
            $logEntry | Out-Null
        }
        ElseIf (-not $DontUseWriteHost){
            # Output to console
            Write-Host $logEntry
        }
        Else {
            # Output to stdout
            Write-Output $logEntry
        }
    }
}

Export-ModuleMember Write-EDXLog

<#
.Synopsis
   Picks a CSV file for processing
.DESCRIPTION
   Opens an interactive file picker dialog to choose a CSV file
.OUTPUTS
   File path of a CSV file
#>
Function Import-EDXCSVWithUI {
    [CmdletBinding()]
    param (
    )
    begin {
        [string]$Title = "Select a CSV file"
    }
    process {

        Add-Type -AssemblyName System.Windows.Forms

        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "CSV files (*.csv)|*.csv"
        $OpenFileDialog.Title = $Title

        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $FilePath = $OpenFileDialog.FileName
            try {
                $ImportedCSV = Import-Csv -Path $FilePath
                Write-Host "CSV file imported successfully."
                return $ImportedCSV
            } catch {
                Write-Error "Failed to import the CSV file. Error: $_"
            }
        } else {
            Write-Host "No file selected."
        }
    }
}

Export-ModuleMember Import-EDXCSVWithUI

<#
.Synopsis
   Securely saves EdgeDX Credentials
.DESCRIPTION
   Uses the Windows DPAPI to save credentials to the caller's AppData\Roaming folder for use in the current or subsequent sessions.
.PARAMETER Tenant
   The EdgeDX Tenant name
.PARAMETER APIKey
   The API Key to be securely saved
.PARAMETER DeviceAccessToken
   The Device Access Token to be securely saved
.PARAMETER NoSaveCredentials
   Erases any existing saved credentials and prompts for credentials for the current session. The supplied credentials are not persisted.
.OUTPUTS
   Returns the credentials in cleartext
.EXAMPLE
   Save-EDXSecrets

   Uses an interactive dialog to enter the tenant name and the API Key
.EXAMPLE
   Save-EDXSecrets -Tenant 'mytenant' -APIKey '795b21478aba4fce89656c6903ced0231edebd19ba7c46d1a0a2858ef2dd604f188f493ae9be4635a4b9bf1dff29705b'

   Enters the tenant name and the API Key using command-line parameters.
.EXAMPLE
   $clearSecret = [pscustomobject]@{
       Tenant = 'mytenant'
       APIKey = '795b21478aba4fce89656c6903ced0231edebd19ba7c46d1a0a2858ef2dd604f188f493ae9be4635a4b9bf1dff29705b'
       DeviceAccessToken = 'V2::ey..........DPe1QKvAc0'
   }
   $clearSecret | Save-EDXSecrets

   Enters the tenant name and the API Key using command-line parameters. (The DeviceAccessToken has been shortened and simplified for the sake of clarity.)
.NOTES
   When used without any parameters the script uses Get-Credential to accept the tenant name and the API Key only.
   For the (rarer) use case where the /device api endpoint is used, a Device Access Token is required, rather than an API Key.
   The Device Access Token length exceeds the size of secret supported by Get-Credential, so all secrets must be entered either
   as command-line parameters, or via the pipeline using named properties.
#>
Function Save-EDXSecrets {
    [CmdletBinding()]
    param (
        [parameter(ParameterSetName = 'Interactive')]
        [parameter(ParameterSetName = 'Silent',ValueFromPipelineByPropertyName = $true,mandatory = $true)][string]$Tenant,
        [parameter(ParameterSetName = 'Silent',ValueFromPipelineByPropertyName = $true,mandatory = $true)][string]$APIKey,
        [parameter(ParameterSetName = 'Silent',ValueFromPipelineByPropertyName = $true,mandatory = $false)][string]$DeviceAccessToken,
        [parameter(mandatory = $false, HelpMessage = 'Do not persist credentials to disk.')][switch]$NoSaveCredentials
    )
    $ParameterSet = $PSCmdlet.ParameterSetName
   # Write-Host -ForegroundColor Cyan "Mode: $ParameterSet"
    $WhatToDo = "This allows your EdgeDX secret(s) to be encrypted and stored using the windows DPAPI.  Only this user can decrypt it!`nEnter tenant name for the username and the APIKey as the password so that it can be used in API scripting."
   # Write-Host $WhatToDo

    # check for stored credential
    If (-not $NoSaveCredentials -and (Test-Path -Path $script:SecureSecretStoreFile -PathType Leaf)) {
        $Credential = Import-Clixml -pa $script:SecureSecretStoreFile
    } Else {
        # no stored credential: create store, get credential and save it
        $parent = Split-Path $script:SecureSecretStoreFile -parent
        if ( -not ( Test-Path -Path $parent -PathType Container) ) {
            New-Item -ItemType Directory -Force -Path $parent
        }
        $Credential = [pscustomobject]@{
            Tenant = $Tenant                          # will be set in Silent mode but null in Interactive mode
            SecureStringAPIKey = $null
            SecureStringDeviceAccessToken = $null
        }
        if ($ParameterSet -eq 'Interactive') {
            #
            # get the API Key
            $GetCredentialSplat = @{
                Message = $WhatToDo -replace "`n",'  '
            }
            if (-not [string]::IsNullOrWhiteSpace($Tenant)) {
                $GetCredentialSplat['UserName'] = $Tenant
            }
            $APIKeyCredential = Get-Credential @GetCredentialSplat
            #$APIKeyCredential = $host.ui.PromptForCredential("Need APIKey", "Please enter the tenant name and API Key.", "", "",[System.Management.Automation.PSCredentialTypes]::Generic,[System.Management.Automation.PSCredentialUIOptions]::None)
            $Credential.Tenant = $APIKeyCredential.UserName
            $Credential.SecureStringAPIKey = $APIKeyCredential.Password
            <#
            #
            # get the Device Access Token
            $GetCredentialSplat = @{
                Message = $WhatToDo -replace "APIKey",'Device Access Token'
            }
            if (-not [string]::IsNullOrWhiteSpace($Credential.Tenant)) {
                $GetCredentialSplat['UserName'] = $Credential.Tenant
            }
            #$DeviceAccessTokenCredential = Get-Credential @GetCredentialSplat
            #$DeviceAccessTokenCredential = $host.ui.PromptForCredential("Need Device Access Token", "Please enter the tenant name and Device Access Token.", "", "",[System.Management.Automation.PSCredentialTypes]::Generic,[System.Management.Automation.PSCredentialUIOptions]::None)
            Write-Host "Need Device Access Token: "
            $Credential.SecureStringDeviceAccessToken = $host.UI.ReadLineAsSecureString()
            #$Credential.Tenant = $DeviceAccessTokenCredential.UserName
            #$Credential.SecureStringDeviceAccessToken = $DeviceAccessTokenCredential.Password
            #>
        }
        else {
            [System.Security.SecureString]$SecurePassword = ConvertTo-SecureString $APIKey -AsPlainText -Force
            $Credential.SecureStringAPIKey = $SecurePassword
            [System.Security.SecureString]$SecurePassword = ConvertTo-SecureString $DeviceAccessToken -AsPlainText -Force
            $Credential.SecureStringDeviceAccessToken = $SecurePassword
        }
    }
    #
    # at this point, we want to return the credential, in cleartext - or null
    #
    if ($NoSaveCredentials) {
        if (Test-Path -Path $script:SecureSecretStoreFile) {
            Remove-Item -Path $script:SecureSecretStoreFile -Force
        }
    }
    else {
        if ($Credential) {
            $Credential | Export-CliXml -Path $script:SecureSecretStoreFile
			Write-Host "Secrets for tenant $($Credential.Tenant) encrypted and stored in $($script:SecureSecretStoreFile)"
        }
    }
    # return the secrets
    if ($Credential) {
        $ClearTextCredential = [pscustomobject]@{
            Tenant = $Credential.Tenant
            APIKey = $null
            DeviceAccessToken = $null
        }
        $SecureStringAPIKey = $Credential.SecureStringAPIKey
        if ($SecureStringAPIKey -ne $null) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringAPIKey) 
            $ClearTextCredential.APIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        $SecureStringDeviceAccessToken = $Credential.SecureStringDeviceAccessToken
        if ($SecureStringDeviceAccessToken -ne $null) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringDeviceAccessToken) 
            $ClearTextCredential.DeviceAccessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        $ClearTextCredential
    }
}

Export-ModuleMember Save-EDXSecrets

<#
.Synopsis
   Retrieves the saved EdgeDX credentials
.DESCRIPTION
   Uses the Windows DPAPI to retrieve the EdgeDX credentials last saved by Save-EDXSecrets.
.OUTPUTS
   Returns an object containing at least the following fields:
   * Tenant - the tenant name
   * APIKey - the cleartext of the API Key
   * DeviceAccessToken - the cleartext of the Device Access Token, if present, else null
#>
Function Restore-EDXSecrets {
    If (Test-Path -Path $script:SecureSecretStoreFile -PathType Leaf) {
        $credentials = Import-Clixml -Path $script:SecureSecretStoreFile
        $EdgeDXCredential = [pscustomobject]@{
            Tenant            = $credentials.Tenant
            APIKey            = $null
            DeviceAccessToken = $null
        }
        @('SecureStringAPIKey','SecureStringDeviceAccessToken') | ForEach-Object {
            $SourceField = $_
            $TargetField = $SourceField -replace 'SecureString',''
            $password = $credentials.$SourceField
            if ($password -ne $null) {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password) 
                $EdgeDXCredential.$TargetField = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            }
        }
        return $EdgeDXCredential
    }
    Else {
        $Message = "Can't find credential file $($script:SecureSecretStoreFile). Please use Function Save-EDXSecrets to store API creds"
        Write-EDXLog -Message $Message
        throw $Message
    }
}

Export-ModuleMember Restore-EDXSecrets

<#
.Synopsis
   Securely manages EdgeDX Credentials
.DESCRIPTION
   Sets the credentials for the current session. In default operation the cmdlet checks for existing saved credentials, and automatically prompts for credentials if none can be found.
   Uses the Windows DPAPI to save credentials to the caller's AppData\Local folder for use in the current or subsequent sessions.
   The credentials are always inserted into the current session, but will not be persisted if -NoSaveCredentials is specified.
.PARAMETER UpdateCredentials
   Prompts the user to supply credentials. This parameter is only required where existing persisted credentials need to be replaced, for example,
   when an API key has expired and a new, generated key needs to replace the expired key.
.PARAMETER NoSaveCredentials
   Erases any existing saved credentials and prompts for credentials for the current session. The supplied credentials are not persisted.
.PARAMETER Tenant
   The EdgeDX Tenant name
.PARAMETER APIKey
   The API Key to be securely saved
.PARAMETER DeviceAccessToken
   The Device Access Token to be securely saved
.OUTPUTS
   Null
.EXAMPLE
   Set-EDXSecrets

   If no secret has previously been set, the cmdlet uses an interactive dialog to enter the tenant name and the API Key.
   If an existing credential file is detected, those credentials are used.
.EXAMPLE
   Set-EDXSecrets -NoSaveCredentials

   The cmdlet uses an interactive dialog to enter the tenant name and the API Key. The cmdlet also accepts credentials from the pipeline or as arguments
   If an existing credential file is detected, the file is deleted.
.EXAMPLE
   Set-EDXSecrets -Tenant 'mytenant' -APIKey '795b21478aba4fce89656c6903ced0231edebd19ba7c46d1a0a2858ef2dd604f188f493ae9be4635a4b9bf1dff29705b'

   Enters the tenant name and the API Key using command-line parameters.
.EXAMPLE
   $clearSecret = [pscustomobject]@{
       Tenant = 'mytenant'
       APIKey = '795b21478aba4fce89656c6903ced0231edebd19ba7c46d1a0a2858ef2dd604f188f493ae9be4635a4b9bf1dff29705b'
       DeviceAccessToken = 'V2::ey..........DPe1QKvAc0'
   }
   $clearSecret | Set-EDXSecrets

   Enters the tenant name and the API Key using command-line parameters. (The DeviceAccessToken has been shortened and simplified for the sake of clarity.)
.NOTES
   When used without any parameters the script uses Get-Credential to accept the tenant name and the API Key only.
   For the (rarer) use case where the /device api endpoint is used, a Device Access Token is required, rather than an API Key.
   The Device Access Token length exceeds the size of secret supported by Get-Credential, so must be entered either as command-line
   parameters, or via the pipeline using named properties.
#>
function Set-EDXSecrets {
    [CmdletBinding(DefaultParameterSetName = 'Persist')]
    param (
        [parameter(mandatory = $false, ParameterSetName = 'Persist')][switch]$UpdateCredentials,
        [parameter(mandatory = $false, ParameterSetName = 'Transient')][switch]$NoSaveCredentials,
        [parameter(mandatory = $false, ValueFromPipelineByPropertyName = $true)][string]$Tenant,
        [parameter(mandatory = $false, HelpMessage = 'The api key for accessing your Edge tenant, in cleartext.', ValueFromPipelineByPropertyName = $true)][string]$APIKey,
        [parameter(mandatory = $false, HelpMessage = 'The device access token for accessing your Edge tenant, in cleartext.', ValueFromPipelineByPropertyName = $true)][string]$DeviceAccessToken
    )
    switch ($PSCmdlet.ParameterSetName) {
        'Persist' {
                #
                # in 'Persist' mode, we look for DPAPI-stored credentials in appdata and use those.
                # If there are no stored credentials, we prompt for them and persist them for next time
                try {
                    Restore-EDXSecrets | Set-EDXSessionAuthorization
                }
                catch {
                    #
                    # prompt for EDX secrets and save them
                    Save-EDXSecrets | Out-Null
                    $EdgeDXCredentialSet = Restore-EDXSecrets
                    $tenant = $EdgeDXCredentialSet.Tenant
                    $APIKey = $EdgeDXCredentialSet.APIKey
                    Set-EDXSessionAuthorization -APIKey $APIKey -Tenant $Tenant
                }
            }
        'Transient' {
                #
                # in 'Transient' mode, we delete any DPAPI-stored credentials in appdata.
                # Credentials must be supplied. We check for them in the pipeline first, then prompt the user if none are available
                $CredentialHash = @{}
                if (-not [string]::IsNullOrWhiteSpace($Tenant)) {
                    $CredentialHash['Tenant'] = $Tenant
                }
                if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
                    $CredentialHash['APIKey'] = $APIKey
                }
                if (-not [string]::IsNullOrWhiteSpace($DeviceAccessToken)) {
                    $CredentialHash['DeviceAccessToken'] = $DeviceAccessToken
                }
                if ($CredentialHash.Count -ge 2) {
                    $ClearTextCredential = [pscustomobject]$CredentialHash
                    $ClearTextCredential | Save-EDXSecrets -NoSaveCredentials | Set-EDXSessionAuthorization
                }
                else {
                    Save-EDXSecrets -NoSaveCredentials | Set-EDXSessionAuthorization
                }
            }
    }
}

Export-ModuleMember Set-EDXSecrets

<#
.Synopsis
   Retrieves the EdgeDX API Key
.DESCRIPTION
   Calls Restore-EDXSecrets to retrieve just the API Key.
.OUTPUTS
   Returns the saved API Key as cleartext
#>
Function Get-EDXAPIKey {
    $EdgeDXCredential = Restore-EDXSecrets
    $EdgeDXCredential.APIKey
}

Export-ModuleMember Get-EDXAPIKey

<#
.Synopsis
   Builds a query URL
.DESCRIPTION
   The script has two functions
   1) It builds a query to return the schema from an API that supports filtering of results
   2) It builds a query to return filtered data from an API that supports filtering of results
.PARAMETER Endpoint
   The name of the API endpoint to be queried
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER Filters
   An array of filters. Each filter must be specified as a hashtable, consisting of 3 elements:
   * Field - the fieldname to be tested
   * Type - the operator used to assess the field matching
   * Value - the value against which the field is to be assessed (using the operator specified by the Type element)
.PARAMETER Sorters
   An array of sorters. Each sorter must be specified as a hashtable, consisting of 2 elements:
   * Field - the fieldname for sorting
   * Dir - set to 'asc' (for ascending sort) or 'desc' (for descending sort)
.PARAMETER Export
   Causes all records to be returned, up to a maximum of 10,000 rows. May be used in conjunction with -Fieldlist,
   to select specific fields to be returned
.PARAMETER FieldList
   Restricts the fields returned. Only valid when Export is set
.PARAMETER Size
   Defines the number of records to be returned when working in 'paged output' mode.
.PARAMETER Page
   Defines the page number to be returned when working in 'paged output' mode. Pages are numbered from 1.
.PARAMETER From
   Skips 'From' rows from the data returned when working in 'paged output' mode.
.PARAMETER SchemaOnly
   Forces the script to return no data, just the schema
.NOTES
   This function has only been tested for internal use, as called from Get-EDXData
.OUTPUTS
   The URL string, constructed from the supplied parameters
#>
Function Get-EDXQueryUrl {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$Endpoint,
        [parameter(mandatory = $false)][string]$Tenant,
        [parameter(mandatory = $false)][object[]]$Filters,
        [parameter(mandatory = $false)][object[]]$Sorters,
        [parameter(mandatory = $true,  ParameterSetName='Export')][switch]$Export,
        [parameter(mandatory = $false, ParameterSetName='Export')][string[]]$FieldList,
        [parameter(mandatory = $false, ParameterSetName='NoExport')][int]$Size,
        [parameter(mandatory = $false, ParameterSetName='NoExport')][int]$Page,
        [parameter(mandatory = $false, ParameterSetName='NoExport')][int]$From,
        [parameter(mandatory = $false)][switch]$SchemaOnly
    )

    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    # Construct the base URL using the tenant name
    $Endpoint = $Endpoint.TrimStart("*api/")
    $BaseUrl = "https://$Tenant.sip.controlup.com/api/$Endpoint"

    # Construct the base query URL
    $queryUrl = "$($BaseUrl)"
    $parameters = @()

    # Add filters to the query URL
    If ($Filters){
        for ($FilterIndex = 0; $FilterIndex -lt $Filters.Count; $FilterIndex++) {
            $filter      = $Filters[$FilterIndex]
            $field       = [uri]::EscapeDataString($filter.Field)
            $type        = [uri]::EscapeDataString($filter.Type)
            $value       = [uri]::EscapeDataString($filter.Value)
            $parameters += "filters[$FilterIndex][field]=$field"
            $parameters += "filters[$FilterIndex][type]=$type"
            $parameters += "filters[$FilterIndex][value]=$value"
        }
    }
    # Add sorters to the query URL
    If ($Sorters){
        for ($SorterIndex = 0; $SorterIndex -lt $Sorters.Count; $SorterIndex++) {
            $sorter      = $Sorters[$SorterIndex]
            $field       = [uri]::EscapeDataString($sorter.Field)
            $dir         = [uri]::EscapeDataString($sorter.Dir)
            $parameters += "sorters[$SorterIndex][field]=$field"
            $parameters += "sorters[$SorterIndex][dir]=$dir"
        }
    }
    $FieldCount = 0
    If ($FieldList.Count -gt 0){
        $FieldList | Sort-Object -Descending | ForEach-Object {
            $FieldName = $_
            $parameters += "_source[$FieldCount]=$FieldName"
            $FieldCount++
        }
    }
    If ($SchemaOnly){
        $parameters += "size=0" # Retrieves just the indexes and fields
    }
    Elseif ($Export) {
        $parameters += "export=true" # full export, to 10000 record limit
    }
    if ("export=true" -notin $parameters) {
        #
        # page / size may be present - either may be defaulted, so no cross-checking needed
        if ($Page -gt 0) {
            $parameters += "page=$Page"
        }
        if ($Size -gt 0) {
            $parameters += "size=$Size"
        }
        if ($From -gt 0) {
            $parameters += "from=$From"
        }
    }
    if ($parameters.Count -gt 0) {
        $parameterList = $parameters -join '&'
        $queryUrl += "?$parameterList"
    }

    Write-EDXLog -Message "INFO: API Query URL - $($queryUrl)"
    return $queryUrl 
}

Export-ModuleMember Get-EDXQueryUrl

<#
.Synopsis
   Queries an EdgeDX endpoint for filterable data
.DESCRIPTION
   The script performs a query to return filtered data from an API that supports filtering of results
.PARAMETER Endpoint
   The name of the API endpoint to be queried
.PARAMETER Filters
   An array of filters. Each filter must be specified as a hashtable, consisting of 3 elements:
   * Field - the fieldname to be tested
   * Type - the operator used to assess the field matching
   * Value - the value against which the field is to be assessed (using the operator specified by the Type element)
.PARAMETER Export
   Causes all records to be returned, up to a maximum of 65,536 rows. If export is not used, then a maximum of 10,000 records is enforced.
   May be used in conjunction with -Fieldlist, to select specific fields to be returned.
   If set, then the parameters Page, Size and From cannot be used.
.PARAMETER FieldList
   Restricts the fields returned. Only valid when Export is set
.PARAMETER Size
   Defines the number of records to be returned when working in 'paged output' mode.
.PARAMETER Page
   Defines the page number to be returned when working in 'paged output' mode. Pages are numbered from 1.
.PARAMETER From
   Skips 'From' rows from the data returned when working in 'paged output' mode.
.PARAMETER SchemaOnly
   Forces the script to return no data, just the schema
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
   If omitted, the function will use the credentials saved by Set-EDXSessionAuthorization
.PARAMETER SortList
   An array of sorters. Each sorter must be specified as a hashtable, consisting of 2 elements:
   * Field - the fieldname for sorting
   * Dir - set to 'asc' (for ascending sort) or 'desc' (for descending sort)
.PARAMETER ReturnURL
   For debugging, adds the constructed URL to the output.
.OUTPUTS
   returns the response from the Invoke-RESTMethod call
.NOTES
   Get-EDXData does not support paging of responses
#>
Function Get-EDXData {
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Name of the endpoint to query.')]
        [ValidateNotNullOrEmpty()]
        [string] $Endpoint,

        [Parameter(Mandatory = $false, HelpMessage = 'Filters for the query.')]
        [ValidateNotNullOrEmpty()]
        [object[]] $Filters,

        [Parameter(Mandatory = $true,  ParameterSetName = 'Export', HelpMessage = 'Explicitly specify the export flag.')]
        [ValidateNotNullOrEmpty()]
        [switch] $Export,

        [Parameter(Mandatory = $false, ParameterSetName = 'Export', HelpMessage = 'Field List to return.')]
        [ValidateNotNullOrEmpty()]
        [string[]] $FieldList,

        [Parameter(Mandatory = $false, ParameterSetName = 'NoExport', HelpMessage = 'Start page of records to fetch.')]
        [ValidateNotNullOrEmpty()]
        [int] $Page,

        [Parameter(Mandatory = $false, ParameterSetName = 'NoExport', HelpMessage = 'Count of records to fetch per page.')]
        [ValidateNotNullOrEmpty()]
        [int] $Size,

        [Parameter(Mandatory = $false, ParameterSetName = 'NoExport', HelpMessage = 'number of records to skip.')]
        [ValidateNotNullOrEmpty()]
        [int] $From,

        [Parameter(Mandatory = $false, HelpMessage = 'Retrieve only the schema.')]
        [switch] $SchemaOnly,

        [Parameter(Mandatory = $false, HelpMessage = 'Tenant of the Organization (can be requested from ControlUp)')]
        [ValidateNotNullOrEmpty()]
        [string] $Tenant,

        [Parameter(Mandatory = $false, HelpMessage = 'The api key for accessing your Edge tenant.')]
        [ValidateNotNullOrEmpty()]
        [string] $APIKey,

        [Parameter(Mandatory = $false, HelpMessage = 'array of sort criteria to sort on.')]
        [ValidateNotNullOrEmpty()]
        [object[]] $SortList,

        [Parameter(Mandatory = $false, HelpMessage = 'Adds the URL to the response object. Useful when debugging')]
        [ValidateNotNullOrEmpty()]
        [switch] $ReturnURL

    )

    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    switch -Regex ($Endpoint) {
#        '^(hello|device)\b' {
#                $NoAutomaticParameters = $true
#                $RowsExpected = $false
#            }
        '^data/\w+(?!/)' {
                $RowsExpected = $true
            }
        '^devices$' {
                $RowsExpected = $true
            }
        '^events$' {
                $RowsExpected = $true
            }
        default {
                $RowsExpected = $false
            }
    }
    # Construct the query URL with the limit for the first record if specified
    $QuerySplat = @{
        Tenant = $Tenant
        Endpoint = $Endpoint
        SchemaOnly = $SchemaOnly
    }
    if ($Filters.Count -gt 0) {
        $QuerySplat['Filters'] = $Filters
    }
    if ($FieldList.Count -gt 0) {
        $QuerySplat['FieldList'] = $FieldList
    }
    if ($Export) {
        $QuerySplat['export'] = $Export
    }
    else {
        if ($Size -gt 0) {
            $QuerySplat['size'] = $Size
        }
        if ($Page -gt 0) {
            $QuerySplat['page'] = $Page
        }
        if ($From -gt 0) {
            $QuerySplat['from'] = $From
        }
    }
    $queryUrl = Get-EDXQueryUrl @QuerySplat

    # Set up the headers with the API key
    if ($queryUrl -match 'sip.controlup.com/api/device\b') {
        #
        # we need a device access token
        $headers = @{"x-access-token" = $script:EDXDeviceToken}
    }
    else {
        #
        # we need an API Key
        if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
            $headers = @{"x-api-key" = $APIKey}
        }
        elseif (-not [string]::IsNullOrWhiteSpace($script:EDXAPIKey)) {
            $headers = @{"x-api-key" = $script:EDXAPIKey}
        }
        else {
            throw "API Key not set - either supply the -APIKey parameter or set the API Key for the session using Set-EDXSessionAuthorization"
        }
    }

    Try {
        # Make the REST API call
        $response = Invoke-RestMethod -Uri $queryUrl -Headers $headers -Method Get
        if ($ReturnURL) {
            $response | Add-Member NoteProperty OriginalURL $queryUrl
        }

        # Check if we received any data
        If ($response -and $response.rows.Count -gt 0) {
            Write-EDXLog -Message "SUCCESS: Retrieved $(($response.rows).count) records."
        } ElseIf ($RowsExpected) {
            Write-EDXLog -Message "FAILURE: No data was found"
        }
    } Catch {
        $exception = $_
        $Message = "An error occurred while making the API call: $($exception.exception.message)"
        Write-EDXLog -Message $Message
        Write-Error $Message
        $response = [pscustomobject]@{OriginalURL = $queryUrl; Exception = $exception}
    }

    return $response
}

Export-ModuleMember Get-EDXData

<#
.Synopsis
   Decodes a URL for analysis
.DESCRIPTION
   The script uses the [System.Uri] class to analyze the provided URL, breaking it down into a BaseURL, the endpoint, and the query parameters
.PARAMETER Url
   The Url to be analyzed
.OUTPUTS
   A PSCustomObject. Fields:
   * BaseUrl         - e.g. https://mytenant.sip.controlup.com
   * Endpoint        - e.g. /api/data/_devices
   * QueryParameters - a PSCustomObject, with each NoteProperty representing a key=value element of the original URL, URL-decoded
.NOTES
   In conjection with Convert-EDXDecodedURLToFilter, Get-EDXDecodedURL enables a Url (e.g. from a Postman session) to
   be adapted for automation in powershell
#>
Function Get-EDXDecodedURL {
    Param (
        [parameter(mandatory = $true)][string]$Url
    )

    # Load System.Web assembly for URL decoding
    Add-Type -AssemblyName System.Web

    # Parse the URL and extract its components
    $uri = [System.Uri]::new($Url)
    $baseUrl = "$($uri.Scheme)://$($uri.Host)"
    if ($uri.Port -ne 80 -and $uri.Port -ne 443) {
        $baseUrl += ":$($uri.Port)"
    }
    $endpoint = $uri.AbsolutePath
    $queryString = $uri.Query.TrimStart('?')

    # Decode query string into a PSCustomObject with note properties
    function Parse-EDXQueryString {
        param (
            [string]$queryString
        )
        $queryObject = New-Object PSObject
        if (-not [string]::IsNullOrWhiteSpace($queryString)) {
            $queryString.Split('&') | ForEach-Object {
                $key, $value = $_ -split '=', 2
                $key = [System.Web.HttpUtility]::UrlDecode($key)
                $value = [System.Web.HttpUtility]::UrlDecode($value)
                $queryObject | Add-Member -NotePropertyName $key -NotePropertyValue $value
            }
        }

        return $queryObject
    }

    $queryObject = Parse-EDXQueryString $queryString

    # Create the final object with base URL, endpoint, and query parameters
    $resultObject = New-Object PSObject -Property @{
        BaseUrl         = $baseUrl
        Endpoint        = $endpoint
        QueryParameters = $queryObject
    }

    return $resultObject
}

Export-ModuleMember Get-EDXDecodedURL

<#
.Synopsis
   Converts a set of filter query parameters to a powershell snippet
.DESCRIPTION
   The QueryParameters array is decoded into tuples of Field,Type,Value
.PARAMETER QueryParameters
   The QueryParameters can be passed in via a command line parameter, but is also designed to accept the object emitted by Get-EDXDecodedURL
.EXAMPLE
   $url = "https://mytenant.sip.controlup.com/api/data/_devices?page=1&size=100&filters%5B0%5D%5Bfield%5D=_updated&filters%5B0%5D%5Btype%5D=%3E%3D&filters%5B0%5D%5Bvalue%5D=2024-07-29T23%3A00%3A00.000Z&filters%5B1%5D%5Bfield%5D=_updated&filters%5B1%5D%5Btype%5D=%3C%3D&filters%5B1%5D%5Bvalue%5D=2024-07-30T22%3A59%3A59.999Z&filters%5B2%5D%5Bfield%5D=group&filters%5B2%5D%5Btype%5D=like&filters%5B2%5D%5BapiColumnType%5D=text&filters%5B2%5D%5Bvalue%5D=tbd%7C%7C%21%21%2A%7C%7CUngrouped&sorters%5B0%5D%5Bfield%5D=_created&sorters%5B0%5D%5Bdir%5D=desc&export=false"
   $decodedURL = Get-EDXDecodedURL -url $url
   $filtercode = Convert-EDXDecodedURLToFilter -QueryParameters $decodedURL.QueryParameters
   Write-Output "`nCopy and paste the below filter code into your API script:`n"
   $filtercode
   Write-Output ""

   In this example, Get-EDXDecodedURL breaks down the supplied Url into separate pieces, and a subsequent call made to Convert-EDXDecodedURLToFilter. This enables the BaseUrl and Endpoint to be retained for other processing

.EXAMPLE
   $url = "https://mytenant.sip.controlup.com/api/data/_devices?page=1&size=100&filters%5B0%5D%5Bfield%5D=_updated&filters%5B0%5D%5Btype%5D=%3E%3D&filters%5B0%5D%5Bvalue%5D=2024-07-29T23%3A00%3A00.000Z&filters%5B1%5D%5Bfield%5D=_updated&filters%5B1%5D%5Btype%5D=%3C%3D&filters%5B1%5D%5Bvalue%5D=2024-07-30T22%3A59%3A59.999Z&filters%5B2%5D%5Bfield%5D=group&filters%5B2%5D%5Btype%5D=like&filters%5B2%5D%5BapiColumnType%5D=text&filters%5B2%5D%5Bvalue%5D=tbd%7C%7C%21%21%2A%7C%7CUngrouped&sorters%5B0%5D%5Bfield%5D=_created&sorters%5B0%5D%5Bdir%5D=desc&export=false"
   $filtercode = Get-EDXDecodedURL -url $url | Convert-EDXDecodedURLToFilter
   Write-Output "`nCopy and paste the below filter code into your API script:`n"
   $filtercode
   Write-Output ""

   In this example, Get-EDXDecodedURL breaks down the supplied Url into separate pieces, which is piped directly into Convert-EDXDecodedURLToFilter. The code is more compact, which may give better maintainability

.OUTPUTS
   The function returns a code snippet that may be incorporated into a powershell script
.NOTES
   The function may be useful to convert a URL built and tested in Postman into a form suitable for automation.
   See also Get-EDXDecodedURL
#>
Function Convert-EDXDecodedURLToFilter {
    Param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCustomObject] $QueryParameters
    )

    Begin {
        $filters = @()
    }

    Process {
        # Group properties by their index
        $groupedProperties = @{}
        $QueryParameters.PSObject.Properties | ForEach-Object {
            if ($_.Name -match 'filters\[(\d+)\]\[(\w+)\]') {
                $index = $matches[1]
                $key = $matches[2]

                if (-not $groupedProperties.ContainsKey($index)) {
                    $groupedProperties[$index] = @{}
                }

                $groupedProperties[$index][$key] = $_.Value
            }
        }

        # Convert grouped properties to array of objects
        $groupedProperties.GetEnumerator() | ForEach-Object {
            $filter = @{
                Field = $_.Value["field"]
                Type  = $_.Value["type"]
                Value = $_.Value["value"]
            }
            $filters += $filter
        }
    }

    End {
        # Generate PowerShell code for the filters array
        $filterArrayCode = $filters | ForEach-Object {
            $field = $_.Field
            $type = $_.Type
            $value = $_.Value
            "@{ Field = `"$field`"; Type = `"$type`"; Value = `"$value`" }"
        }

        $filterArrayCode = "`$filters = @(`n" + ($filterArrayCode -join "`n") + "`n)"
        $filterArrayCode
    }
}

Export-ModuleMember Convert-EDXDecodedURLToFilter

<#
.Synopsis
   Decodes EdgeDX action events
.DESCRIPTION
   Parses event descriptions from an EdgeDX event to identify the user and the payload
.PARAMETER InputString
   The description field from an EdgeDX event where the description is known to contain the substring 'RUN_SCRIPT_V2'
.NOTES
   The function is highly specific to the task of analyzing the running of custom actions, but may serve as a model for other analyses
#>
Function Get-EDXActionDescription {
    param (
        [string]$InputString
    )

    # Use regex to match the email address pattern
    if ($InputString -match 'The user (.*) sent an action') {
        $user = $matches[1]
    }

    # Remove unnecessary escape sequences and extract the payload
    $pattern = 'Command payload:\s*(\{(?:[^{}]|(?<open>\{)|(?<-open>\}))*\}(?(open)(?!)))'
    if ($InputString -match $pattern) {
        $jsonPayload = $matches[1]
    }

    # Convert the cleaned string to a JSON object
    $jsonObject = $jsonPayload | ConvertFrom-Json

    # Check if the 'data' field contains JSON as a string, if so we need to convert it again
    If ($jsonObject.data.gettype().Name -eq "String"){
        $dataJsonObject = $jsonObject.data | ConvertFrom-Json
        $jsonObject.data = $dataJsonObject
    }
    $jsonObject.data | Add-Member -MemberType NoteProperty -Name "User" -Value $user

    return $JsonObject.data
}

Export-ModuleMember Get-EDXActionDescription

<#
.Synopsis
   Queries a data index using the dal
.DESCRIPTION
   Performs basic DAL queries, using a provided JSON payload
.PARAMETER IndexName
   The name of the EdgeDX index to run the query against
.PARAMETER Payload
   The JSON payload corresponding to the DAL Query
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
   If omitted, the function will use the credentials saved by Set-EDXSessionAuthorization
.OUTPUTS
   Structured data, representing the result of the query.
.NOTES
   The functionality is sufficient for basic DAL exploration.
#>
Function Get-EDXDalQuery {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'Index to query.')]
        [ValidateNotNullOrEmpty()]
        [string] $IndexName,

        [Parameter(Mandatory = $true, HelpMessage = 'Payload for the query.')]
        [ValidateNotNullOrEmpty()]
        [object] $Payload,

        [Parameter(Mandatory = $false, HelpMessage = 'Tenant of the Organization (can be requested from ControlUp)')]
        [ValidateNotNullOrEmpty()]
        [string] $Tenant,

        [Parameter(Mandatory = $false, HelpMessage = 'The api key for accessing your Edge tenant.')]
        [ValidateNotNullOrEmpty()]
        [string] $APIKey

    )

    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    # Set URI
    [string]$Uri = "https://$Tenant.sip.controlup.com/api/dal/$IndexName" # single device
    Write-EDXLog -Message "INFO: Using url - $($Uri)"
    # Create header
    #
    # we need an API Key
    if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
        $headers = @{"x-api-key" = $APIKey}
    }
    elseif (-not [string]::IsNullOrWhiteSpace($script:EDXAPIKey)) {
        $headers = @{"x-api-key" = $script:EDXAPIKey}
    }
    else {
        throw "API Key not set - either supply the -APIKey parameter or set the API Key for the session using Set-EDXSessionAuthorization"
    }
    $headers['accept'] = 'application/json'
    $headers['content-type'] = 'application/json'

    # test whether the supplied Payload is already json, or needs to be converted
    $PayloadType = $Payload.GetType()
    switch ($PayloadType.Name) {
        'String' {
                $jsnBody = $Payload
            }
        default {
                $jsnBody = $Payload | ConvertTo-Json -Depth 100
            }
    }

    Write-Verbose -Message ($jsnBody | Out-String)

    try {
        Write-EDXLog -Message "INFO: Running script - $($scriptname) (ScriptID:$ScriptId) on device $($DeviceName) (DeviceID:$DeviceId) on $($Tenant)"
        $return = Invoke-RestMethod -Uri $Uri -Method POST -Headers $headers -Body $jsnBody -ContentType 'application/json'
    }
    catch {
        Write-EDXLog -Message "FAILURE: $($_.Exception.Message)"
        Throw "There was an error trying to run the script via the EdgeDX API:`n$($_.Exception.Message)"
    }

    # Return the _id of the invoked action
    Write-Verbose -Message $return
    $return
}

Export-ModuleMember Get-EDXDalQuery

<#
.Synopsis
   Invokes a script on a device
.DESCRIPTION
   Allows the execution of EdgeDX scripts from outside the EdgeDX tenant interface
.PARAMETER ScriptId
   The internal EdgeDX Id that uniquely identifies the script to be run
.PARAMETER ScriptName
   The name of the script. Only required for logging purposes.
   The caller should be able to provide this from the same API call that returned the ScriptId, so it is more efficient
   to have the name passed in, rather than requiring an extra API call to discover the name.
.PARAMETER DeviceId
   The internal EdgeDX Id that uniquely identifies the device on which the script is to be run
.PARAMETER DeviceName
   The name of the device. Only required for logging purposes.
   The caller should be able to provide this from the same API call that returned the DeviceId, so it is more efficient
   to have the name passed in, rather than requiring an extra API call to discover the name.
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
   If omitted, the function will use the credentials saved by Set-EDXSessionAuthorization
.PARAMETER SessionId
   Identifies the session in which the script should be run. Do not specify -RunAsSystem or -RunForAllUsers with -SessionId
.PARAMETER RunAsSystem
   Causes the script to be run as System. Do not specify -SessionId or -RunForAllUsers with -RunAsSystem
.PARAMETER RunForAllUsers
   Causes the script to be run for all users. Do not specify -RunAsSystem or -SessionId with -RunForAllUsers
.OUTPUTS
   The _id of the invoked action. This may be used to match against events caused by the running of the script, where supported by the endpoint agent implementation.
#>
Function Invoke-EDXDeviceScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The ID of the script to run')][string]$ScriptId,
        [Parameter(Mandatory = $false, HelpMessage = 'The name of the script to run')][string]$ScriptName,  # required only for logging
        [Parameter(Mandatory = $true, HelpMessage = 'The ID of the EdgeDX device.')][array]$DeviceId,
        [Parameter(Mandatory = $false, HelpMessage = 'The Name of the EdgeDX device.')][array]$DeviceName,  # required only for logging
        [Parameter(Mandatory = $false, HelpMessage = 'The Name or URL of the EdgeDX tenant, https:// part is optional and will be removed')][string]$Tenant,
        [Parameter(Mandatory = $false, HelpMessage = 'The API Key for authentication.')][string]$APIKey,
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleSession', HelpMessage = 'The Session Id for the user to run the script for.')][int]$SessionId,
        [Parameter(Mandatory = $true, ParameterSetName = 'RunAsSystem', HelpMessage = 'Run script as system.')][switch]$RunAsSystem,
        [Parameter(Mandatory = $true, ParameterSetName = 'RunForAllUsers', HelpMessage = 'Run script for all users.')][switch]$RunForAllUsers
    )

    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    # Set URI
    [string]$Uri = "https://$Tenant.sip.controlup.com/api/devices/$DeviceId/actions" # single device
    Write-EDXLog -Message "INFO: Using url - $($Uri)"
    # Create header
    #
    # we need an API Key
    if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
        $headers = @{"x-api-key" = $APIKey}
    }
    elseif (-not [string]::IsNullOrWhiteSpace($script:EDXAPIKey)) {
        $headers = @{"x-api-key" = $script:EDXAPIKey}
    }
    else {
        throw "API Key not set - either supply the -APIKey parameter or set the API Key for the session using Set-EDXSessionAuthorization"
    }

    # Create the body
    $data = [ordered]@{}
    $data.add('script_id', $ScriptId)
    if ($SessionId) {
        $data.add('run_as_user', $true)
        $data.add('session_id', $SessionId)
    }
    else {
        $data.add('run_as_user', $false)
        $data.add('session_id', '')
    }
    if ($RunForAllUsers) {
        $data.add('run_all_users', $true)
    }
    else {
        $data.add('run_all_users', $false)
    }

    if ($RunAsSystem) {
        $data.add('run_as_system', $true)
    }
    else {
        $data.add('run_as_system', $false)
    }

    $body = [ordered]@{}
    $body.add('type', 'RUN_SCRIPT_V2')
    $body.add('data', ($data | convertto-json))

    # Fails if not converted to JSON first
    $jsnBody = $body | ConvertTo-Json -Depth 100
    Write-Verbose -Message ($jsnBody | Out-String)

    try {
        Write-EDXLog -Message "INFO: Running script - $($scriptname) (ScriptID:$ScriptId) on device $($DeviceName) (DeviceID:$DeviceId) on $($Tenant)"
        $return = Invoke-RestMethod -Uri $Uri -Method POST -Headers $headers -Body $jsnBody -ContentType 'application/json'
    }
    catch {
        Write-EDXLog -Message "FAILURE: $($_.Exception.Message)"
        Throw "There was an error trying to run the script via the EdgeDX API:`n$($_.Exception.Message)"
    }

    # Return the _id of the invoked action
    Write-Verbose -Message $return
    Return $return._id
}

Export-ModuleMember Invoke-EDXDeviceScript

<#
.Synopsis
   Sets a device group on EdgeDX devices
.DESCRIPTION
   Sets a device group on EdgeDX devices matching the ComputerName - which may be a partial match
.PARAMETER DeviceGroup
   The name of the device group to which computer(s) will be assigned
.PARAMETER ComputerName
   The name of the the computer(s) to be assigned to the device group. 
   The ComputerName is processed by a filter and all computers matching the name will be assigned to the device group
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
   If omitted, the function will use the credentials saved by Set-EDXSessionAuthorization
#>
Function Set-EDXDeviceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = 'Name of the devicegroup to assign')][string]$DeviceGroup,
        [Parameter(Mandatory = $true, HelpMessage = 'Computername to set devicegroup for (partial names are also accepted).')][string]$ComputerName,
        [Parameter(Mandatory = $false, HelpMessage = 'The Name or URL of the EdgeDX tenant, https:// part is optional and will be removed')][string]$Tenant,
        [Parameter(Mandatory = $false, HelpMessage = 'The API Key for authentication.')][string]$APIKey
    )
    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    # Create header
    #
    # we need an API Key
    if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
        $headers = @{"x-api-key" = $APIKey}
    }
    else {
        $headers = @{"x-api-key" = $script:EDXAPIKey}
    }
    $page = 1
    $devices = @()
    do {
        $deviceuri = "https://$Tenant.sip.controlup.com/api/devices?page=$page&size=100&sorters%5B0%5D%5Bfield%5D=name.keyword&sorters%5B0%5D%5Bdir%5D=asc&filters%5B0%5D%5Bfield%5D=name&filters%5B0%5D%5Btype%5D=like&filters%5B0%5D%5Bvalue%5D=$ComputerName"
        $results = Invoke-RestMethod -Method GET -Uri $deviceuri -Headers $headers
        $devices += $results.rows | Select-Object name, _id
        $page++
    }
    until(($devices.count) -ge ($results.rows_available))

    # Set URI
    $body = @{}

    $body.Add('group', $DeviceGroup)
    # Fails if not converted to JSON first
    $jsnBody = $body | ConvertTo-Json -Depth 100

    foreach ($device in $devices) {
        $devicename = $device.name
        $deviceid = $device._id
        [string]$Uri = "https://$Tenant.sip.controlup.com/api/devices/$deviceId"
        try {
            Write-EDXLog -Message "INFO: Setting device group to $($DeviceGroup) on computer $ComputerName on tenant $Tenant"
            $response = Invoke-RestMethod -Uri $Uri -Method POST -Headers $headers -Body $jsnBody -ContentType 'application/json'
            return $response | Out-Null
        }
        catch {
            Write-EDXLog -Message "FAILURE: There was an API error while trying to set device group for $($devicename):`n$($_.Exception.Message)"
            Continue # Continue to next device on error
        }
    }
}

Export-ModuleMember Set-EDXDeviceGroup

<#
.Synopsis
   Sets tag(s) against an EdgeDX device
.DESCRIPTION
   The specified tags will be merged with existing tags.
.PARAMETER Tags
   An array of tags to be applied to the computer(s)
.PARAMETER ComputerName
   The name of the the computer(s) to be tagged. 
   The ComputerName is processed by a filter and all computers matching the name will be assigned to the device group
.PARAMETER Tenant
   The name of the tenant
   If omitted, the function will use the tenant name saved by Set-EDXSessionAuthorization
.PARAMETER APIKey
   The majority of API calls require an API key for their operation. API keys are associated with EdgeDX console users
   and have the exact same permissions as the user. An API key is required for all API calls that are not to /api/device
   If omitted, the function will use the credentials saved by Set-EDXSessionAuthorization
.PARAMETER Action
   The action to be performed - either 'create' or 'delete'
#>
Function Set-EDXDeviceTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Array of tags to assign')][string[]]$Tags,
        [Parameter(Mandatory = $true, HelpMessage = 'Computername to set tags for (partial names are also accepted).')][string]$ComputerName,
        [Parameter(Mandatory = $false, HelpMessage = 'The Name or URL of the EdgeDX tenant, https:// part is optional and will be removed')][string]$Tenant,
        [Parameter(Mandatory = $false, HelpMessage = 'The API Key for authentication.')][string]$APIKey,
        [Parameter(Mandatory = $true, HelpMessage = 'Action to perform: create or delete')][ValidateSet("create", "delete")][string]$Action
    )
    #
    # retrieve tenant if not already set
    if ([string]::IsNullOrWhiteSpace($Tenant) -and (-not [string]::IsNullOrWhiteSpace($script:EDXTenant))) {
        $Tenant = $script:EDXTenant
    }
    elseif ([string]::IsNullOrWhiteSpace($Tenant)) {
        throw "Tenant not set - either supply the -Tenant parameter or set the tenant for the session using Set-EDXSessionAuthorization"
    }
    $Tenant = $Tenant -replace "https:\/\/",'' -replace "\.sip.controlup.com.*",''

    # Create header
    #
    # we need an API Key
    if (-not [string]::IsNullOrWhiteSpace($APIKey)) {
        $headers = @{"x-api-key" = $APIKey}
    }
    else {
        $headers = @{"x-api-key" = $script:EDXAPIKey}
    }
    $page = 1
    $devices = @()
    Do {
        $deviceuri = "https://$Tenant.sip.controlup.com/api/devices?page=$page&size=100&sorters%5B0%5D%5Bfield%5D=name.keyword&sorters%5B0%5D%5Bdir%5D=asc&filters%5B0%5D%5Bfield%5D=name&filters%5B0%5D%5Btype%5D=like&filters%5B0%5D%5Bvalue%5D=$ComputerName"
        $results = Invoke-RestMethod -Method GET -Uri $deviceuri -Headers $headers
        $devices += $results.rows | Select-Object name, _id
        $page++
    }
    Until(($devices.count) -ge ($results.rows_available))
    [array]$ids = $devices._id
    # Set URI
    $body = [ordered]@{}
    $body.Add('ids', $ids)
    $body.Add('tags', $Tags)
    $body.Add('action', $Action.ToLower())
    # Fails if not converted to JSON first
    $jsnBody = $body | ConvertTo-Json -Depth 100
    [string]$Uri = "https://$Tenant.sip.controlup.com/api/devices/tags"

    Try {
        Write-EDXLog -Message "INFO: $($action) device tag $($Tags -join ',') on computer $ComputerName on tenant $Tenant"
        $response = Invoke-RestMethod -Uri $Uri -Method POST -Headers $headers -Body $jsnBody -ContentType 'application/json'
    }
    Catch {
        Write-EDXLog -Message "FAILURE: There was an API error while trying to set tags for $($ComputerName):`n$($_.Exception.Message)"
        Throw "There was an error accessing the EdgeDX API:`n$($_.Exception.Message)"
    }
    Return $response | Out-Null
}

Export-ModuleMember Set-EDXDeviceTag

### Functions #End

