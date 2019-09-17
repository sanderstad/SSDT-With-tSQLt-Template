# SSDT-With-tSQLt-Template
Template how a SSDT project can be setup including tSQLt

To use this template you need the **PSModuleDevelopment** module which is part of the [PSFramework](https://github.com/PowershellFrameworkCollective/psframework) project

## Generate the solution

Use the following command to create a new template from this directory

```powershell
New-PSMDTemplate -ReferencePath [pathtofolder] -TemplateName [nameoftemplate]
```

i.e.

```powershell
New-PSMDTemplate -ReferencePath C:\Users\sande\source\repos\Databases\SSDT-With-tSQLt-Template -TemplateName SSDTWithtSQLt
```

To create a new solution from the template use the following command

```powershell
Invoke-PSMDTemplate -TemplateName [nameoftemplate] -OutPath [path-to-output-to] -Name [nameofproject]
```

i.e.

```powershell
Invoke-PSMDTemplate -TemplateName SSDTWithtSQLt -OutPath C:\Users\sande\source\repos\Databases -Name DatabaseProject1
```

For more guidance on the template system, [visit the documentation pages for the module](https://psframework.org/documentation/documents/psmoduledevelopment/templates.html)

## Generate basic tests for your database
Nothing it more tedious than having to create the same kind of unit tests for all the different objects.

This solution you just created contains a folder called "Scripts".
The scripts folder contains a powershell script that enables you to create basic tests for the already present objects in your database.

The script will create the following tests

- Test if the database collation is correct
- Test if an object exists, it will do this for functions, stored procedures, tables and views
- Test if a function has the correct parameters
- Test if a procedure has the correct parameters
- Test if a table has the correct columns
- Test if a view has the correct columns

### How does it work

The script will iterate through the different objects in the database and create the needed tests.

The tests are created using template files. The template files are located in the directory "TestTemplates" located in the scripts directory.

> You can make changes to the templates as you please to make the tests to your needs.

> Important to note is that it's easier to run the command from the original location. It will be able to find the template directory automatically

### Running the script

To generate the tests for the entire database, run the following command

```powershell
PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic
```

To filter for certain objects use one or more of the following parameters

- Function
- Procedure
- Table
- View

```powershell
PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic -procedure Proc1, Proc2
```

In some cases you may find it easier to skip certain tests

- SkipDatabaseTests
- SkipFunctionTests
- SkipProcedureTests
- SkipTableTests
- SkipViewTests

```powershell
PS C:\> .\Invoke-GenerateBasicTests.ps1 -SqlInstance SQLDB1 -Database DB1 -OutputPath c:\projects\DB1\DB1-Tests\TestBasic -procedure Proc1, Proc2 -SkipTableTests -SkipViewTests
```