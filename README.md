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
Look for the functionality to create basic tSQLt unit tests for this solution to the module "PStSQLtTestGenerator".

To install for everyone

```powershell
Install-Module PStSQLtTestGenerator
```

To install for current user

```powershell
Install-Module PStSQLtTestGenerator -Scope CurrentUser
```

To create the unit tests

```powershell
Invoke-PSTGTestGenerator -SqlInstance [yourinstance] -Database [yourdatabase] -OutputPath [path to SSDT project test folder]
```