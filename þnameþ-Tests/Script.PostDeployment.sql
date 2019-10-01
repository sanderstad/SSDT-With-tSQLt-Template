/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

IF(ISNULL(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT),0) >= 14)
BEGIN
    EXEC tSQLt.InstallExternalAccessKey;
    EXEC master.sys.sp_executesql N'GRANT UNSAFE ASSEMBLY TO [tSQLtExternalAccessKey];';
    EXEC sp_configure 'clr strict security', 1;
    RECONFIGURE;
END
GO

--EXEC tSQLt.RunAll
