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
--DECLARE @cmd NVARCHAR(MAX);
--SET @cmd='ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET TRUSTWORTHY ON;';
--EXEC(@cmd);
GO
