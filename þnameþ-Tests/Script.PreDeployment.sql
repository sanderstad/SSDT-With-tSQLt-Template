/*
 Pre-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.
 Use SQLCMD syntax to include a file in the pre-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the pre-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO
IF(ISNULL(CAST(SERVERPROPERTY('ProductMajorVersion') AS INT),0) >= 14)
BEGIN
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'clr strict security', 0;
    RECONFIGURE;
END
--DECLARE @cmd NVARCHAR(MAX);
--SET @cmd='ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET TRUSTWORTHY ON;';
--EXEC(@cmd);
GO
