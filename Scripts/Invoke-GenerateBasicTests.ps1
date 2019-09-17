<#
    .SYNOPSIS
        Create the basic tests for the database project

    .DESCRIPTION
        The script will connect to a database on a SQL Server instance, iterate through objects and create tests for the objects.

        The script will create the following tests
        - Test if the database settings (i.e. collation) are correct
        - Test if an object (Function, Procedure, Table, View etc) exists
        - Test if an object (Function or Procedure) has the correct parameters
        - Test if an object (Table or View) has the correct columns

        Each object and each test will be it's own file.

   .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

        This should be the primary replica.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Database
        The database or databases to add.

    .PARAMETER OutputPath
        Folder where the files should be written to

    .PARAMETER TemplateFolder
        The template folder containing all the templates for the tests.
        By default it will try to look it up in the same directory as this script with the name "TestTemplates"

    .PARAMETER Function
        Filter out specific functions that should only be processed

    .PARAMETER Procedure
        Filter out specific procedures that should only be processed

    .PARAMETER Table
        Filter out specific tables that should only be processed

    .PARAMETER View
        Filter out specific views that should only be processed

    .PARAMETER SkipDatabaseTest
        Skip the database tests

    .PARAMETER SkipFunctionTests
        Skip the function tests

    .PARAMETER SkipProcedureTests
        Skip the procedure tests

    .PARAMETER SkipTableTests
        Skip the table tests

    .PARAMETER SkipViewTests
        Skip the view tests

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic

        Iterate through all the objects and output the files to "c:\projects\DB1\DB1-Tests\TestBasic"

    .EXAMPLE
        PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic -Procedure Proc1, Proc2

        Iterate through all the objects but only do "Proc1" and "Proc2" for the procedures.

        NOTE! All other tests like the table, function and view tests will still be generated

    .EXAMPLE
        PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic -SkipProcedureTests

        Iterate through all the objects but do not process the procedures
    #>

[CmdletBinding()]

param(
    [DbaInstanceParameter]$SqlInstance,
    [pscredential]$SqlCredential,
    [string]$Database,
    [string]$OutputPath,
    [string]$TemplateFolder,
    [string[]]$Function,
    [string[]]$Procedure,
    [string[]]$Table,
    [string[]]$View,
    [switch]$SkipDatabaseTests,
    [switch]$SkipFunctionTests,
    [switch]$SkipProcedureTests,
    [switch]$SkipTableTests,
    [switch]$SkipViewTests,
    [switch]$EnableException
)

# Check if neccesary modules are installed
if (-not (Get-Module -ListAvailable -Name "PSFramework" -Verbose:$false)) {
    Write-Warning -Message "Please install PSFramework before continuing."
    return
}

# Import the module
Import-Module PSFramework -Verbose:$false

if (-not (Get-Module -ListAvailable -Name "dbatools" -Verbose:$false)) {
    Stop-PSFFunction -Message "Please install dbatools before continuing."
    return
}

# Import the modules
Import-Module dbatools -Verbose:$false

# Check the parameters
if (-not $SqlInstance) {
    Stop-PSFFunction -Message "Please enter a SQL Server instance" -Target $SqlInstance
    return
}

if (-not $Database) {
    Stop-PSFFunction -Message "Please enter a database" -Target $Database
    return
}

if (-not $OutputPath) {
    Stop-PSFFunction -Message "Please enter path to output the files to" -Target $OutputPath
    return
}

if (-not $TemplateFolder) {
    $TemplateFolder = Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath "TestTemplates"
}

if (-not (Test-Path -Path $TemplateFolder)) {
    Stop-PSFFunction -Message "Could not find template folder" -Target $OutputPath
    return
}

# Connect to the server
try {
    $server = Connect-DbaInstance -SqlInstance $Sqlinstance -SqlCredential $SqlCredential
}
catch {
    Stop-PSFFunction -Message "Could not connect to '$Sqlinstance'" -Target $Sqlinstance -ErrorRecord $_ -Category ConnectionError
}

# Check if the database exists
if ($Database -notin $server.Databases.Name) {
    Stop-PSFFunction -Message "Database cannot be found on '$SqlInstance'" -Target $Database
}

#########################################################################
# Internal functions
#########################################################################
function New-tSQLtDatabaseCollationTest {
    param(
        [Parameter(Mandatory)][string]$Database,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If database has correct collation Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Import the template
    try {
        $script = Get-Content -Path ".\TestTemplates\DatabaseCollationTest.template"
    }
    catch {
        Stop-PSFFunction -Message "Could not import test template 'DatabaseCollationTest.template'" -Target $testName -ErrorRecord $_
    }

    # Replace the markers with the content
    $script = $script.Replace("___TESTNAME___", $testName)
    $script = $script.Replace("___DATABASE___", $Database)
    $script = $script.Replace("___COLLATION___", $server.Databases[$Database].Collation)
    $script = $script.Replace("___CREATOR___", $creator)
    $script = $script.Replace("___DATE___", $date)

    # Write the test
    try {
        Write-PSFMessage -Message "Creating collation test for '$Database'"
        $script | Out-File -FilePath $fileName
    }
    catch {
        Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
    }
}

function New-tSQLtFunctionParameterTest {
    param(
        [Parameter(Mandatory)][object]$Function,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If function $($Function.Schema).$($Function.Name) has the correct parameters Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Get the parameters
    $parameters = $Function.Parameters

    if ($parameters.Count -ge 1) {
        # Import the template
        try {
            $script = Get-Content -Path ".\TestTemplates\FunctionParameterTest.template"
        }
        catch {
            Stop-PSFFunction -Message "Could not import test template 'FunctionParameterTest.template'" -Target $testName -ErrorRecord $_
        }

        $paramTextCollection = @()

        # Loop through the parameters
        foreach ($parameter in $parameters) {
            $paramText = "`t('$($parameter.Name)', '$($parameter.DataType.Name)', $($parameter.DataType.MaximumLength), $($parameter.DataType.NumericPrecision), $($parameter.DataType.NumericScale))"
            $paramTextCollection += $paramText
        }

        # Replace the markers with the content
        $script = $script.Replace("___TESTNAME___", $testName)
        $script = $script.Replace("___SCHEMA___", $Function.Schema)
        $script = $script.Replace("___NAME___", $Function.Name)
        $script = $script.Replace("___CREATOR___", $creator)
        $script = $script.Replace("___DATE___", $date)
        $script = $script.Replace("___PARAMETERS___", ($paramTextCollection -join ",`n") + ";")

        # Write the test
        try {
            Write-PSFMessage -Message "Creating function parameter test for function '$($Function.Schema).$($Function.Name)'"
            $script | Out-File -FilePath $fileName
        }
        catch {
            Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
        }
    }
    else {
        Write-PSFMessage -Message "Function $($Function.Schema).$($Function.Name) does not have any parameters. Skipping..."
    }
}

function New-tSQLtObjectExistenceTest {
    param(
        [ValidateSet('Function', 'Procedure', 'Table', 'View')]
        [Parameter(Mandatory)][string]$ObjectType,
        [Parameter(Mandatory)][string]$Schema,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If $($ObjectType.ToLower()) $($Schema).$($Name) exists Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Import the template
    try {
        $script = Get-Content -Path ".\TestTemplates\ObjectExistence.template"
    }
    catch {
        Stop-PSFFunction -Message "Could not import test template 'ObjectExistence.template'" -Target $testName -ErrorRecord $_
    }

    # Replace the markers with the content
    $script = $script.Replace("___TESTNAME___", $testName)
    $script = $script.Replace("___OBJECTTYPE___", $ObjectType.ToLower())
    $script = $script.Replace("___SCHEMA___", $Schema)
    $script = $script.Replace("___NAME___", $Name)
    $script = $script.Replace("___CREATOR___", $creator)
    $script = $script.Replace("___DATE___", $date)

    # Write the test
    try {
        Write-PSFMessage -Message "Creating existence test for $($ObjectType.ToLower()) '$($Schema).$($Name)'"
        $script | Out-File -FilePath $fileName
    }
    catch {
        Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
    }
}

function New-tSQLtProcedureParameterTest {
    param(
        [Parameter(Mandatory)][object]$Procedure,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If procedure $($Procedure.Schema).$($Procedure.Name) has the correct parameters Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Get the parameters
    $parameters = $Procedure.Parameters

    if ($parameters.Count -ge 1) {
        # Import the template
        try {
            $script = Get-Content -Path ".\TestTemplates\ProcedureParameterTest.template"
        }
        catch {
            Stop-PSFFunction -Message "Could not import test template 'ProcedureParameterTest.template'" -Target $testName -ErrorRecord $_
        }

        $paramTextCollection = @()

        # Loop through the parameters
        foreach ($parameter in $parameters) {
            $paramText = "`t('$($parameter.Name)', '$($parameter.DataType.Name)', $($parameter.DataType.MaximumLength), $($parameter.DataType.NumericPrecision), $($parameter.DataType.NumericScale))"
            $paramTextCollection += $paramText
        }

        # Replace the markers with the content
        $script = $script.Replace("___TESTNAME___", $testName)
        $script = $script.Replace("___SCHEMA___", $Procedure.Schema)
        $script = $script.Replace("___NAME___", $Procedure.Name)
        $script = $script.Replace("___CREATOR___", $creator)
        $script = $script.Replace("___DATE___", $date)
        $script = $script.Replace("___PARAMETERS___", ($paramTextCollection -join ",`n") + ";")

        # Write the test
        try {
            Write-PSFMessage -Message "Creating procedure parameter test for procedure '$($Procedure.Schema).$($Procedure.Name)'"
            $script | Out-File -FilePath $fileName
        }
        catch {
            Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
        }
    }
    else {
        Write-PSFMessage -Message "Procedure $($Procedure.Schema).$($Procedure.Name) does not have any parameters. Skipping..."
    }
}

function New-tSQLtTableColumnTest {
    param(
        [Parameter(Mandatory)][object]$Table,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If table $($Table.Schema).$($Table.Name) has the correct columns Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Import the template
    try {
        $script = Get-Content -Path ".\TestTemplates\TableColumnTest.template"
    }
    catch {
        Stop-PSFFunction -Message "Could not import test template 'TableColumnTest.template'" -Target $testName -ErrorRecord $_
    }

    # Get the columns
    $columns = $Table.Columns

    $columnTextCollection = @()

    # Loop through the columns
    foreach ($column in $columns) {
        $columnText = "`t('$($column.Name)', '$($column.DataType.Name)', $($column.DataType.MaximumLength), $($column.DataType.NumericPrecision), $($column.DataType.NumericScale))"
        $columnTextCollection += $columnText
    }

    # Replace the markers with the content
    $script = $script.Replace("___TESTNAME___", $testName)
    $script = $script.Replace("___SCHEMA___", $Table.Schema)
    $script = $script.Replace("___NAME___", $Table.Name)
    $script = $script.Replace("___CREATOR___", $creator)
    $script = $script.Replace("___DATE___", $date)
    $script = $script.Replace("___COLUMNS___", ($columnTextCollection -join ",`n") + ";")

    # Write the test
    try {
        Write-PSFMessage -Message "Creating table column test for table '$($Table.Schema).$($Table.Name)'"
        $script | Out-File -FilePath $fileName
    }
    catch {
        Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
    }
}

function New-tSQLtViewColumnTest {
    param(
        [Parameter(Mandatory)][object]$View,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $testName = "test If table $($View.Schema).$($View.Name) has the correct columns Expect Success"

    # Test if the name of the test does not become too long
    if ($testName.Length -gt 128) {
        Stop-PSFFunction -Message "Name of the test is too long" -Target $testName
    }

    $fileName = Join-Path -Path $OutputPath -ChildPath "$($testName).sql"
    $date = Get-Date -Format (Get-culture).DateTimeFormat.ShortDatePattern
    $creator = $env:username

    # Import the template
    try {
        $script = Get-Content -Path ".\TestTemplates\ViewColumnTest.template"
    }
    catch {
        Stop-PSFFunction -Message "Could not import test template 'ViewColumnTest.template'" -Target $testName -ErrorRecord $_
    }

    # Get the columns
    $columns = $View.Columns

    $columnTextCollection = @()

    # Loop through the columns
    foreach ($column in $columns) {
        $columnText = "`t('$($column.Name)', '$($column.DataType.Name)', $($column.DataType.MaximumLength), $($column.DataType.NumericPrecision), $($parameter.DataType.NumericScale))"
        $columnTextCollection += $columnText
    }

    # Replace the markers with the content
    $script = $script.Replace("___TESTNAME___", $testName)
    $script = $script.Replace("___SCHEMA___", $View.Schema)
    $script = $script.Replace("___NAME___", $View.Name)
    $script = $script.Replace("___CREATOR___", $creator)
    $script = $script.Replace("___DATE___", $date)
    $script = $script.Replace("___COLUMNS___", ($columnTextCollection -join ",`n") + ";")

    # Write the test
    try {
        Write-PSFMessage -Message "Creating table column test for table '$($View.Schema).$($View.Name)'"
        $script | Out-File -FilePath $fileName
    }
    catch {
        Stop-PSFFunction -Message "Something went wrong writing the test" -Target $testName -ErrorRecord $_
    }
}

#########################################################################
# Create the database tests
#########################################################################

if (-not $SkipDatabaseTests) {
    # Create the collation test
    New-tSQLtDatabaseCollationTest -Database $Database -OutputPath $OutputPath



}

#########################################################################
# Create the function tests
#########################################################################
if (-not $SkipFunctionTests) {
    # Get all the procedures
    $functions = $server.Databases[$Database].UserDefinedFunctions | Where-Object { $_.IsSystemObject -eq $false }

    if ($Function) {
        $functions = $functions | Where-Object Name -in $Function
    }

    # Loop through each of the tables
    foreach ($f in $functions) {
        # Create the procedure existence tests
        New-tSQLtObjectExistenceTest -ObjectType Function -Schema $f.Schema -Name $f.Name -OutputPath $OutputPath

        # Create the procedure parameters tests
        New-tSQLtFunctionParameterTest -Function $f -OutputPath $OutputPath
    }
}

#########################################################################
# Create the procedure tests
#########################################################################
if (-not $SkipProcedureTests) {
    # Get all the procedures
    $procedures = $server.Databases[$Database].StoredProcedures | Where-Object { $_.IsSystemObject -eq $false }

    if ($Procedure) {
        $procedures = $procedures | Where-Object Name -in $Procedure
    }

    # Loop through each of the tables
    foreach ($p in $procedures) {
        # Create the procedure existence tests
        New-tSQLtObjectExistenceTest -ObjectType Procedure -Schema $p.Schema -Name $p.Name -OutputPath $OutputPath

        # Create the procedure parameters tests
        New-tSQLtProcedureParameterTest -Procedure $p -OutputPath $OutputPath
    }
}

#########################################################################
# Create the table tests
#########################################################################
if (-not $SkipTableTests) {
    # Get the tables
    $tables = $server.Databases[$Database].Tables

    if ($Table) {
        $tables = $tables | Where-Object Name -in $Table
    }

    # Loop through each of the tables
    foreach ($t in $tables) {
        # Create the table existence tests
        New-tSQLtObjectExistenceTest -ObjectType Table -Schema $t.Schema -Name $t.Name -OutputPath $OutputPath

        # Create the column tests
        New-tSQLtTableColumnTest -Table $t -OutputPath $OutputPath
    }
}

#########################################################################
# Create the view tests
#########################################################################
if (-not $SkipViewTests) {
    # Get all the procedures
    $views = $server.Databases[$Database].Views | Where-Object { $_.IsSystemObject -eq $false }

    if ($View) {
        $views = $views | Where-Object Name -in $View
    }

    # Loop through each of the tables
    foreach ($v in $views) {
        # Create the procedure existence tests
        New-tSQLtObjectExistenceTest -ObjectType View -Schema $v.Schema -Name $v.Name -OutputPath $OutputPath

        # Create the procedure parameters tests
        New-tSQLtProcedureParameterTest -Procedure $v -OutputPath $OutputPath
    }
}