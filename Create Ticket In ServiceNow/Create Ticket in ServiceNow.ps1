# For more information check this Blog https://www.controlup.com/10-simple-steps-to-build-your-own-integration-in-controlup/

$caller = $args[0]
$logonduration = $args[1]
$machinename = $args[2]
$username = $args[3]
$password = $args[4]
$instanceid = $args[5]

# Put API Call URL in parameter consuming $instanceid from above
$apicallurl = "https://$instanceid.service-now.com/api/now/table/incident"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Basic $base64AuthInfo")

$body = "{
`n `"short_description`": `"Logon Duration Incident`",
`n `"caller_id`": '$caller',
`n `"cmdb_ci`": '$machinename',
`n `"description`": `"User's Logon Duration was $logonduration seconds`"
`n}"

$response = Invoke-RestMethod $apicallurl -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
