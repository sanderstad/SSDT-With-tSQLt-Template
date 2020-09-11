<#
This script publishes that runs the tSQLt tests
#>

param(
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [string]$SqlUserName = 'sa',
    [string]$SqlPassword,
    [string]$Database,
    [string]$TestResultPath,
    [string]$TestFileName = "TEST-$($Database)_tSQLt.xml",
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
else {
    $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential

    if ($server.Databases.Name -notcontains $Database) {
        Stop-PSFFunction -Message "The database $($Database) is not present on $($SqlInstance)" -Target $TestResultPath
        return
    }
}

if (-not $TestResultPath) {
    Stop-PSFFunction -Message "Please enter a path to save the test results in" -Target $TestResultPath
    return
}
else {
    if (-not (Test-Path -Path $TestResultPath)) {
        try {
            Write-PSFMessage -Level Important -Message "Creating test results directory"
            $null = New-Item -Path $TestResultPath -ItemType Directory -Force
        }
        catch {
            Stop-PSFFunction -Message "Could not create test results directory" -Target $TestResultPath -ErrorRecord $_
            return
        }
    }
}

# Execute tests
$query = "EXEC tSQLt.RunAll"

#try {
    Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $query
#}
#catch {
#    Stop-PSFFunction -Message "Something went wrong running the tests" -Target $Database -ErrorRecord $_
#    return
#}

# Collect the tests
$query = "EXEC tSQLt.XmlResultFormatter"
try {
    $result = Invoke-DbaQuery -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database -Query $query | Select-Object ItemArray -ExpandProperty ItemArray
}
catch {
    Stop-PSFFunction -Message "Something went wrong collecting the tSQLt test results" -Target $Database -ErrorRecord $_
    return
}

# Write the test results
try {
    $result | Set-Content -NoNewLine -Path (Join-Path -Path $TestResultPath -ChildPath $TestFileName)
}
catch {
    Stop-PSFFunction -Message "Something went wrong writing the tSQLt test results" -Target $TestResultPath -ErrorRecord $_
    return
}