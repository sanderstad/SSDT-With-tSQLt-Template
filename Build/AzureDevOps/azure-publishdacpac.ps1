<#
This script publishes the dacpac to the sql server instance.
#>

param(
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [string]$SqlUserName = 'sa',
    [string]$SqlPassword,
    [string]$Database,
    [string]$DacPacFilePath,
    [string]$PublishXmlFile,
    [switch]$EnableException
)

# Check parameters
if (-not $SqlInstance) {
    Stop-PSFFunction -Message "Please enter a SQL Server instance" -Target $SqlInstance
    return
}

if (-not $SqlCredential -and -not $SqlUserName -and -not $SqlPassword) {
    Stop-PSFFunction -Message "Please enter a credential" -Target $SqlInstance
    return
}

if (-not $SqlCredential -and ($SqlUserName -and $SqlPassword)) {
    $password = ConvertTo-SecureString $SqlPassword -AsPlainText -Force;
    $SqlCredential = New-Object System.Management.Automation.PSCredential($SqlUserName, $password);
}

if (-not $Database) {
    Stop-PSFFunction -Message "Please enter a database" -Target $Database
    return
}

if (-not $DacPacFilePath) {
    Stop-PSFFunction -Message "Please enter a DACPAC file" -Target $DacPacFile
    return
}
elseif (-not (Test-Path -Path $DacPacFilePath)) {
    Stop-PSFFunction -Message "Could not find DACPAC file" -Target $DacPacFile
    return
}

if (-not $PublishXmlFile) {
    Stop-PSFFunction -Message "Please enter a publish profile file" -Target $PublishXmlFile
    return
}
elseif (-not (Test-Path -Path $PublishXmlFile)) {
    Stop-PSFFunction -Message "Could not find publish profile" -Target $PublishXmlFile
    return
}

try {
    $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
    Write-PSFMessage -Level Important -Message $server.Name
}
catch {
    Stop-PSFFunction -Message "Could not connect. `n$_"  -Target $SqlInstance -ErrorRecord $_
}


# Publish the DACPAC file

$params = @{
    SqlInstance   = $SqlInstance
    SqlCredential = $SqlCredential
    Database      = $Database
    Path          = $DacPacFilePath
    PublishXml    = $PublishXmlFile
}

try {
    Write-PSFMessage -Level Important -Message "Publishing DACPAC to $SqlInstance"
    Publish-DbaDacPackage @params -EnableException
}
catch {
    Stop-PSFFunction -Message "Could not publish DACPAC" -Target $SqlInstance -ErrorRecord $_ -Continue
}