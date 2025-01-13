#
# module to manage signing, importing, exporting and cloning of CU SBAs
#

#
# work out if the map file exists
$Script:SchemaXsdFile = Join-Path $PSScriptRoot "SBAXml.xsd"
if (-not (Test-Path -LiteralPath $Script:SchemaXsdFile -PathType Leaf)) {
    throw "NOT FOUND: Schema file $Script:SchemaXsdFile"
}

$Script:CompressionMode = [System.IO.Compression.CompressionMode]::Decompress

#
# while this code could just as easily have been written in powershell, unfortunately
# some anti-malware software treats the sequence: base64 -> byte array -> gunzip -> byte array
# as being indicative of malware and nukes the module file
#
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.IO.Compression;
using System.Text;

public class CUCompress
{
    public static byte[] ConvertBase64ToByteArray(string InputString,int BufferSize)
    {
        byte[] gzipData = Convert.FromBase64String(InputString);
        if (gzipData[0] == 0x1f && gzipData[1] == 0x8b)
        {
            var stream = new MemoryStream();
            stream.Write(gzipData, 0, gzipData.Length);
            stream.Seek(0, 0);
            var gzstream = new GZipStream(stream, CompressionMode.Decompress);
            var BinaryReader = new BinaryReader(gzstream);
            byte[] uncompressedString = BinaryReader.ReadBytes(BufferSize);
            return uncompressedString;
        }
        else
        {
            return gzipData;
        }
    }

    public static string ConvertByteArrayToBase64(byte[] InputBytes)
    {
        var ms = new MemoryStream();
        var cs = new GZipStream(ms, CompressionMode.Compress);
        cs.Write(InputBytes, 0, InputBytes.Length);
        cs.Close();
        var converted = Convert.ToBase64String(ms.ToArray());
        ms.Close();
        return converted;

    }
}
"@


<#
.SYNOPSIS
   Calculates the SHA1 checksum of an array of bytes
.DESCRIPTION
   This is used to sign the encoded script in the XML file, and to check that the file has been exported properly.
   The function returns the SHA1 checksum in different formats, for convenience
.PARAMETER Bytes
   The array of bytes to be checksummed
#>
function Get-SHA1Checksum {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][byte[]]$Bytes
    )
    $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $HashByteArray = $sha1.ComputeHash($Bytes)
    $HashString = [System.BitConverter]::ToString($HashByteArray) -replace "-",''
    [pscustomobject]@{
        HashString = $HashString
        HashBytes = $HashByteArray
        Base64Hash = [convert]::ToBase64String($HashByteArray)
    }
}

<#
.SYNOPSIS
   Validates a ControlUp Script Xml file against an XSD schema file
.DESCRIPTION
   The default schema was created using https://www.freeformatter.com/xsd-generator.html#before-output and has been hand-edited.
   See also: https://stackoverflow.com/questions/822907/how-do-i-use-powershell-to-validate-xml-files-against-an-xsd
.PARAMETER ScriptXml
   Path of the Script XML file
.PARAMETER SchemaFile
   Path of the Script XML Schema (XSD) file
.PARAMETER ValidationEventHandler
   Event handler for processing schema errors. The default handler writes the exception to the error stream
#>
function Test-CUSBAScriptXmlSchema
{
    [CmdletBinding()]
    [outputtype([boolean])]

    param (     
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [alias('Fullname')]
        [string] $ScriptXml,

        [Parameter(Mandatory=$false)]
        [string] $SchemaFile,


        [scriptblock] $ValidationEventHandler = { Write-Error $args[1].Exception }
    )

    begin {
        if ([string]::IsNullOrWhiteSpace($SchemaFile)) {
            $SchemaFile = $Script:SchemaXsdFile
        }
        if (-not (Test-Path -LiteralPath $SchemaFile -PathType Leaf)) {
            throw "NOT FOUND: Schema file $SchemaFile"
        }
        $schemaReader = New-Object System.Xml.XmlTextReader $SchemaFile
        $schema = [System.Xml.Schema.XmlSchema]::Read($schemaReader, $ValidationEventHandler)
    }

    process {
        $ret = $true
        try {
            $xml = New-Object System.Xml.XmlDocument
            $xml.Schemas.Add($schema) | Out-Null
            $xml.Load($ScriptXml)
            $xml.Validate({
                    throw ([PsCustomObject] @{
                        SchemaFile = $SchemaFile
                        ScriptXml = $ScriptXml
                        Exception = $args[1].Exception
                    })
                })
        } catch {
            Write-Host -ForegroundColor red $_.Exception.Message 
            $ret = $false
        }
        $ret
    }

    end {
        $schemaReader.Close()
    }
}

Export-ModuleMember Test-CUSBAScriptXmlSchema

<#
.SYNOPSIS
   Validates the script contents within a ControlUp Script Xml file
.DESCRIPTION
   Checks that the script within the Xml file matches the checksum
.PARAMETER ScriptXml
   Path of the Script XML file
#>
function Validate-CUSBAXmlFile {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$ScriptXml
    )
    begin {}
    process {
        if (-not (Test-Path -LiteralPath $ScriptXml)) {
            throw "ScriptXml file not found: $ScriptXml"
        }
        #
        # now extract the PS1 file as 'raw' to a byte array, and validate the checksum
        $ScriptXMLPath = (Resolve-Path -LiteralPath $ScriptXML).Path
        $XmlText = Get-Content -LiteralPath $ScriptXMLPath
        $XmlDoc = [xml]$XmlText
        $ScriptBase64Text = $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData

        # see https://sphinx.graae.dk/pages/gzipcompressionandbase64encoding/
        $ExpectedSize = 50000
        do {
            $ExpectedSize = $ExpectedSize * 2
            $ScriptBytes = [CUCompress]::ConvertBase64ToByteArray($ScriptBase64Text,$ExpectedSize)
        } until ($ScriptBytes.Count -lt $ExpectedSize)
        
        #
        # calculate checksums
        $HashRecord = Get-SHA1Checksum -Bytes $ScriptBytes

        $CheckSumBase64 = $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.CheckSum    # base 64 encoded, 28 bytes long?

        $CheckSumBase64 -eq $HashRecord.Base64Hash
    }
    end {}
}

Export-ModuleMember Validate-CUSBAXmlFile

<#
.SYNOPSIS
   Clones an XML file, making it suitable for developing a new script
.DESCRIPTION
   The code creates new dates and guids for all relevant fields, and sets a new script name.
   The next step would normally be to run Import-CUScript to bring in a new PS1 file, prior to uploading
   the script under test to a ControlUp Realtime console for the development/test cycle.
.PARAMETER TemplateXml
   Path of the Template script XML file. Normally this would be any existing script XML file, reasonably close in function.
   The Template file is not changed by the cloning operation
.PARAMETER NewName
   The name (title) of the new script, as it should appear in the ControlUp Realtime console
.PARAMETER OutputFolder
   Path of the folder where the new Script XML file will be created. 
   If not set, the new Script XML file will be created in the same folder as the Template file
#>
function Clone-CUSBAXmlFile {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$TemplateXml,
        [parameter(mandatory = $true)][string]$NewName,
        [parameter(mandatory = $false)][string]$OutputFolder
    )
    begin {}
    process {
        if (-not (Test-Path -LiteralPath $TemplateXml)) {
            throw "TemplateXml not found: $TemplateXml"
        }
        $SourceXMLFileObj = Get-Item $TemplateXml

        $XmlText = Get-Content -LiteralPath $TemplateXml
        $XmlDoc = [xml]$XmlText

        $NowString = (Get-Date).ToString('O')
        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.DateCreated = $NowString
        if (-not [string]::IsNullOrWhiteSpace($XmlDoc.ArrayOfSBADescriptor.SBADescriptor.DateModified)) {
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.DateModified = $NowString
        }
        else {
            $DateModifiedElement = $XmlDoc.CreateElement("DateModified")
            $DateModifiedElement.InnerText = $NowString
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.AppendChild($DateModifiedElement)
        }
        ($XmlDoc.ArrayOfSBADescriptor.SBADescriptor.ChildNodes | Where-Object { $_.Name -in @(<#'DateModified',#>'DatePublished') } ) | 
            ForEach-Object {
                [void]$_.ParentNode.RemoveChild($_)
            }

        [version]$v = '0.0.1'
        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.Version = ([version]::new($v.Major,$v.Minor,$v.Build)).ToString()

        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.SBAId = ([guid]::NewGuid().Guid).ToString()
        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.RootSBAId = ([guid]::NewGuid().Guid).ToString()
        $guid = ([guid]::NewGuid().Guid).ToString()
        try {
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.StoreId = $guid
        }
        catch {
            $StoreIdElement = $XmlDoc.CreateElement("StoreId")
            $StoreIdElement.InnerText = $guid
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.AppendChild($StoreIdElement)
        }

        if ([string]::IsNullOrWhiteSpace($OutputFolder)) {
            $OutputFolder = $SourceXMLFileObj.DirectoryName
        }
        if (-not [string]::IsNullOrWhiteSpace($NewName)) {
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.Name = $NewName
            $XmlFileName = $NewName + '.xml'
        }
        else {
            $XmlFileName = 'SBA Sample.xml'
        }
        $TargetXMLPath = Join-Path -Path $OutputFolder -ChildPath $XmlFileName
        if (-not (Test-Path -LiteralPath $TargetXMLPath)) {
            $XmlDoc.Save($TargetXMLPath)
        }
        else {
            throw "File already exists: $TargetXMLPath"
        }
        return $TargetXMLPath
    }
    end {}
}

Export-ModuleMember Clone-CUSBAXmlFile

<#
.SYNOPSIS
   Imports a powershell or other script into an existing XML file
.DESCRIPTION
   The function takes a cleartext powershell script, encoded as UTF16 LE BOM (this is not checked) 
   The script is read as bytes, then compressed using gzip and converted to Base64 excoding
   The SHA1 checksum for the file is generated and also written to the XML file 
.PARAMETER ScriptXml
   Path of the Script XML file
.PARAMETER ScriptPs1
   Path of the imported Script PS1 file
#>
function Import-CUScript {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$ScriptXml,
        [parameter(mandatory = $true)][string]$ScriptPs1
    )
    begin {}
    process {
        if (-not (Test-Path -LiteralPath $ScriptXML)) {
            throw "XML Script file not found: '$ScriptXML'"
        }
        if (-not (Test-Path -LiteralPath $ScriptPS1)) {
            throw "PS1 Script file not found: '$ScriptPS1'"
        }
        $ScriptXMLPath = (Resolve-Path -LiteralPath $ScriptXML).Path
        $XmlText = Get-Content -LiteralPath $ScriptXMLPath
        $XmlDoc = [xml]$XmlText

        # see https://stackoverflow.com/questions/71811761/how-do-i-convert-a-powershell-script-to-base64
        $Data = [IO.File]::ReadAllBytes($ScriptPS1)
        $converted = [CUCompress]::ConvertByteArrayToBase64($Data)
        $HashRecord = Get-SHA1Checksum -Bytes $Data

        #
        # update version & timestamp
        if (-not $NoTouch) {
            [version]$v = $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.Version
            $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.Version = ([version]::new($v.Major,$v.Minor,$v.Build + 1)).ToString()
            $NowString = (Get-Date).ToString('O')
            if (-not [string]::IsNullOrWhiteSpace($XmlDoc.ArrayOfSBADescriptor.SBADescriptor.DateModified)) {
                $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.DateModified = $NowString
            }
            else {
                $DateModifiedElement = $XmlDoc.CreateElement("DateModified")
                $DateModifiedElement.InnerText = $NowString
                $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.AppendChild($DateModifiedElement)
            }
        }

        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData = $converted
        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.IsCompressed = 'true'
        $XmlDoc.ArrayOfSBADescriptor.SBADescriptor.CheckSum = $HashRecord.Base64Hash

        $XmlDoc.Save($ScriptXML)
    }
    end {}
}

Export-ModuleMember Import-CUScript

<#
.SYNOPSIS
   Exports a script from within an XML file to cleartext
.DESCRIPTION
   The function converts the Base64 encoding to a byte stream and performs a gunzip operation
   The SHA1 checksum is calculated for the output file and checked against the value in the XML file
.PARAMETER ScriptXml
   Path of the Script XML file
.PARAMETER ScriptPs1
   Path of the exported Script PS1 file
#>
function Export-CUScript {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)][string]$ScriptXml,
        [parameter(mandatory = $true)][string]$ScriptPs1
    )
    begin {
    }
    process {
        if (-not (Test-Path -LiteralPath $ScriptXML)) {
            throw "XML Script file not found: '$ScriptXML'"
        }
        $ScriptXMLPath = (Resolve-Path -LiteralPath $ScriptXML).Path
        $XmlText = Get-Content -LiteralPath $ScriptXMLPath
        $XmlDoc = [xml]$XmlText

        $ScriptBase64Text = $XMLDoc.ArrayOfSBADescriptor.SBADescriptor.ExecutionDescriptor.ScriptData
  #      $FileBytes = [CUCompress]::ConvertBase64ToByteArray($ScriptBase64Text)
        $ExpectedSize = 50000
        do {
            $ExpectedSize = $ExpectedSize * 2
            $FileBytes = [CUCompress]::ConvertBase64ToByteArray($ScriptBase64Text,$ExpectedSize)
        } until ($FileBytes.Count -lt $ExpectedSize)
        [io.file]::WriteAllBytes($ScriptPs1,$FileBytes)
        $HashRecord = Get-SHA1Checksum -Bytes $FileBytes

        #
        # now do checksums...
        # does the temp file we've just unpacked match?
        if ($HashRecord.Base64Hash -ne $XMLDoc.ArrayOfSBADescriptor.SBADescriptor.CheckSum) {
            throw "Checksum mismatch"
        }
    }
    end {
    }
}

Export-ModuleMember Export-CUScript

<#
.SYNOPSIS
   checks whether a certificate is capable of being used to sign code
.DESCRIPTION
   The function checks the supplied certificate for the relevant metadata
.PARAMETER Certificate
   An X509Certificate object
#>
function Is-CodeSigningCertificate {
    [CmdletBinding()]
    [outputtype([boolean])]

    param (
        [parameter (mandatory = $true)][object]$Certificate
    )
    $IsCodeSigningCert = $false
    $Certificate.EnhancedKeyUsageList | ForEach-Object {
        $KeyUsage = $_
        if ($KeyUsage.FriendlyName -eq 'Code Signing') {
            $IsCodeSigningCert = $true
        }
    }
    return $IsCodeSigningCert
}

<#
.SYNOPSIS
   Sign a script that's embedded in an XML file
.DESCRIPTION
   The function extracts the script from a CU script XML file to a temporary file and signs the script, overwriting any previous signature
   The signed script is then written back to the CU script XML file
   Specifying a timestamp server is optional, but strongly recommended.
.PARAMETER ScriptXml
   Path of the Script XML file
.PARAMETER CertificateId
   The certificate to be used for signing the script.
   This may be specified as
   * an X509Certificate object
   * the certificate's FriendlyName
   * the certificate's Subject
   * the certificate's Thumbprint
   * the certificate's Path in the certificate store
.PARAMETER BypassSchemaChecks
   If set, the function will not check the Script XML file for conformity with the schema.
.PARAMETER TimeStampServer
   The URL of the certificate timestamp server. See the help for Set-AuthenticodeSignature for an explanation of this parameter.
#>
function Sign-CUScript {
    [CmdletBinding()]
    param (
        [parameter (mandatory = $true)][string]$ScriptXml,
        [parameter (mandatory = $true)][object]$CertificateId,
        [parameter (mandatory = $false)][switch]$BypassSchemaChecks,
        [parameter (mandatory = $false)][string]$TimeStampServer
    )
    begin {
        #
        $Certificate = $null
        $ValidationStatus = $true
        #
        # check whether timestamp
        #
        # test that the file exists and conforms to the schema
        if (Test-Path -LiteralPath $ScriptXml -PathType Leaf) {
            if (-not $BypassSchemaChecks) {
                $ValidationStatus = Test-CUSBAScriptXmlSchema -ScriptXml $ScriptXml # will throw an exception if it doesn't match
                if($ValidationStatus -ne $true){
                    Write-Host -ForegroundColor red "The XML has not passed validation"
                }
            }
        }
        else {
            throw "Script file not found: $ScriptXml"
        }
        #
        # work out the certificate to be used, based on any of Path, Thumbprint, Name or FriendlyName
        $IdType = $CertificateId.GetType()
        if ($IdType.Name -eq 'X509Certificate2') {
            $Certificate = $CertificateId
        }
        elseif ($IdType.Name -eq 'string') {
            if ($CertificateId -like "Cert:*") {
                if (Test-Path -LiteralPath $CertificateId -PathType Leaf) {
                    $Certificate = Get-Item -LiteralPath $CertificateId
                }
                else {
                    throw "Certificate not found $($CertificateId.ToString())"
                }
            }
            else {
                [object[]]$CertificateList = Get-ChildItem cert:\ -Recurse | 
                    Where-Object {$_.HasPrivateKey} | 
                    Where-Object {Is-CodeSigningCertificate -Certificate $_} | 
                    Where-Object {($_.FriendlyName -eq $CertificateId) -or ($_.Subject -eq $CertificateId) -or ($_.Thumbprint -eq $CertificateId)}
                switch ($CertificateList.Count) {
                    0 {
                            throw "No suitable certificate from supplied Id $($CertificateId.ToString())"
                        }
                    default {
                            $Certificate = $CertificateList[0]
                        }
                }
            }
        }
        else {
            throw "unable to identify certificate from supplied Id $($CertificateId.ToString())"
        }
        #
        # check that the certificate is suitable
        if ($Certificate -eq $null) {
            throw "unable to match supplied CertificateId $($CertificateId.ToString())"
        }
        elseif (-not $Certificate.HasPrivateKey) {
            throw "Certificate does not have a private key, so cannot be used for signing $($CertificateId.ToString())"
        }
        else {
            if (-not (Is-CodeSigningCertificate -Certificate $Certificate)) {
                throw "Certificate cannot be used for signing $($CertificateId.ToString())"
            }
        }
        #
        # work out a unique temporary folder name
        $TempFolder = [System.IO.Path]::GetTempPath()
        if ([string]::IsNullOrWhiteSpace($TempFolder)) {
            $TempFolder = 'C:\Windows\SystemTemp'  # in case running as system and the regular environment variables aren't set up
        }
        $subfolder = ('cusign_' + [System.IO.Path]::GetRandomFileName()) -replace "\..*",''
        $script:TemporaryFolderForInstallers = Join-Path -Path $TempFolder -ChildPath $subfolder
        New-Item -Path $script:TemporaryFolderForInstallers -ItemType Directory | Out-Null
    }
    process {
        #
        # we have a valid file and a certificate - let's go!
        if($ValidationStatus -ne $true){
            return
        }
        try {
            $PS1File = ((Split-Path -Path $ScriptXml -Leaf) -replace "(\..*){0,1}$",'') + '.ps1'  # substitute any extension or none with .ps1
            $PS1Path = Join-Path -Path $script:TemporaryFolderForInstallers -ChildPath $PS1File
            Export-CUScript -ScriptXml $ScriptXml -ScriptPs1 $PS1Path
            #
            # check that the extracted file has UTF16 LE BOM encoding
            $BOMType = Get-FileBOMType -Path $PS1Path -AddNoBOMGuess
            if ($BOMType -ne 'UTF16 LE') {
                throw "Unexpected BOM Type $BOMType in script in file $ScriptXml"
            }
            # PARAMETERS:
            # FilePath - Specifies the file path of the PowerShell script to sign, eg. C:\ATA\myscript.ps1.
            # Certificate - Specifies the certificate to use when signing the script.
            # TimeStampServer - Specifies the trusted timestamp server that adds a timestamp to your script's digital signature. 
            # Adding a timestamp ensures that your code will not expire when the signing certificate expires.
            $SASSplat = @{
                 FilePath = $PS1Path
                 Certificate = $Certificate
            }
            if (-not [string]::IsNullOrWhiteSpace($TimeStampServer)) {
                $SASSplat['TimeStampServer'] = $TimeStampServer
            }
            $retSign = Set-AuthenticodeSignature @SASSplat
            $retImport  = Import-CUScript -ScriptXml $ScriptXml -ScriptPs1 $PS1Path
        }
        catch {
            $exception = $_
            # clean up & re-throw exception
            if (Test-Path -LiteralPath $script:TemporaryFolderForInstallers -PathType Container) {
                Remove-Item -LiteralPath $script:TemporaryFolderForInstallers -Force -Recurse
            }
            throw $exception
        }
    }
    end {
        #
        # clean up
        if (Test-Path -LiteralPath $script:TemporaryFolderForInstallers -PathType Container) {
            Remove-Item -LiteralPath $script:TemporaryFolderForInstallers -Force -Recurse
        }
    }
}

Export-ModuleMember Sign-CUScript

<#
.SYNOPSIS
   prettifies a script XML file
.DESCRIPTION
   Script XML files downloaded from the CU console are typically squashed into a very small number of lines, making it hard to compare and edit such files
   This function rewrites the XML using no more than one element per line
.PARAMETER ScriptXml
   Path of the Script XML file
#>
function Prettify-CUScriptXml {
    [CmdletBinding()]
    param (
        [parameter (mandatory=$true)] [string] $ScriptXml
    )
    if (-not (Test-Path -LiteralPath $ScriptXml)) {
        throw "ScriptXml not found: $ScriptXml"
    }

    $XmlText = Get-Content -LiteralPath $ScriptXml
    $XmlDoc = [xml]$XmlText
    $XmlDoc.Save($ScriptXml)
}

Export-ModuleMember Prettify-CUScriptXml

<#
.SYNOPSIS
   Reads the BOM type of a file
.DESCRIPTION
   Powershell scripts need to be encoded as UTF16 LE BOM in order to function correctly in the Realtime console or as SBAs for a trigger
   The function checks the first 4 bytes of a file and reports the BOM Type detected
.PARAMETER Path
   Path of file to be checked
.PARAMETER AddNoBOMGuess
   If set, the script will test the initial 4 bytes of a BOM-less file and attempt to work out whether big-endian or little-endian encoding has been used
#>
function Get-FileBOMType {
    [CmdletBinding()]
    [outputtype([string])]

    param (
        [parameter(Mandatory = $true)][string]$Path,
        [parameter(mandatory = $false)][switch]$AddNoBOMGuess
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "not a file: $Path"
    }
    #
    # test to see there is no Byte Order Mark (BOM)
    $contents = new-object byte[] 4
    $stream = [System.IO.File]::OpenRead($Path)
    $BytesRead = $stream.Read($contents, 0, 4)
    while ($BytesRead -lt 4) {
        $contents[$BytesRead] = 0xaa
        $BytesRead++
    }
    $stream.Close()
    $BOMType = 'none'
    switch ($contents[0]) {
        0xEF {
                if ($contents[1] -eq 0xbb -and $contents[2] -eq 0xbf) {
                    $BOMType = 'UTF8'
                }
            }
        0xFF {
                if ($contents[1] -eq 0xfe -and $contents[2] -eq 0x00 -and $contents[3] -eq 0x00) {
                    $BOMType = 'UTF32 LE'
                }
                elseif ($contents[1] -eq 0xfe) {
                    $BOMType = 'UTF16 LE'
                }
            }
        0xFE {
                if ($contents[1] -eq 0xff) {
                    $BOMType = 'UTF16 BE'
                }
            }
        0x00 {
                if ($contents[1] -eq 0x00 -and $contents[2] -eq 0xfe -and $contents[3] -eq 0xff) {
                    $BOMType = 'UTF32 BE'
                }
            }
        default {
        }
    }
    if (($BOMType -eq 'none') -and $AddNoBOMGuess) {
       if ($contents[0] -eq 0x00 -and $contents[1] -ne 0x00 -and $contents[2] -eq 0x00 -and $contents[3] -ne 0x00) {
           $BOMType = 'UTF16 BE'
       }
       elseif ($contents[0] -ne 0x00 -and $contents[1] -eq 0x00 -and $contents[2] -ne 0x00 -and $contents[3] -eq 0x00) {
           $BOMType = 'UTF16 LE'
       }
    }
    $BOMType
}

Export-ModuleMember Get-FileBOMType

<#
.SYNOPSIS
   Reads the BOM encoding of a file
.DESCRIPTION
   Powershell scripts need to be encoded as UTF16 LE BOM in order to function correctly in the Realtime console or as SBAs for a trigger
   The function checks the first 4 bytes of a file and reports the encoding detected as a string that is suitable for the -Encoding
   parameter of a Get-COntent or Set-Content
.PARAMETER Path
   Path of file to be checked
#>
function Get-FileBOMEncoding {
    [CmdletBinding()]
    [outputtype([string])]

    param (
        [parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "not a file: $Path"
    }
    $BOMType = Get-FileBOMType -Path $Path -AddNoBOMGuess
    switch ($BOMType) {
        'UTF8' {'UTF8'}
        'UTF32 LE' {'UTF32'}
        'UTF32 BE' {'BigEndianUTF32'}
        'UTF16 LE' {'Unicode'}
        'UTF16 BE' {'BigEndianUnicode'}
        default {'Default'}
    }
}

Export-ModuleMember Get-FileBOMEncoding
