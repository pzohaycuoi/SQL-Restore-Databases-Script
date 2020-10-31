-- 16/10/2020
-- Backup databases script vao trong timestamped folder de chay tu dong voi task-scheduler tren primary server

USE master;
GO

-- Bat xp_cmdshell
EXECUTE sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;  
GO  

-- @path variable chua path dan den folder chua timestamped backup folder
DECLARE @Path NVARCHAR(256)
-- doi Path thanh Path chua folder backup mong muon
SET @Path = 'D:\Test-AACC-DBs\Backup\'

-- @getTheDate variable chua date luc script nay chay theo form dd-mm-yyyy
DECLARE @getTheDate NVARCHAR(1000)
SET @getTheDate = CONVERT(VARCHAR(10),GETDATE(),105)

-- @backupPath chua path cua folder timestamped backup folder
DECLARE @backupPath NVARCHAR(256)
SET @backupPath = @Path + @getTheDate + '\'

-- @cmdCreatetimestampedFolder cmd tao timestamped folder de chua file .bak
DECLARE @cmdCreateTimestampedFolder NVARCHAR(256)
SET @cmdCreateTimestampedFolder = N'EXEC XP_CMDSHELL ''mkdir @backupPath'''
-- Su dung replace de thay the string '@backupPath' thanh variable @backupPath
SET @cmdCreateTimestampedFolder = REPLACE(@cmdCreateTimestampedFolder,'@backupPath',@backupPath)
	EXEC sp_executesql @cmdCreateTimestampedFolder

-- @DBName variable chua database name cua cursor
-- @backupFileName chua path va file name backup cua file backup
DECLARE @DBName NVARCHAR(256)
DECLARE @backupFileName NVARCHAR(256)

-- dbCursor con tro de fetch database name
DECLARE dbCursor CURSOR
	FOR SELECT
		name
	FROM
		sys.databases
	WHERE
		name IS NOT NULL AND name NOT IN ('master','model','msdb','tempdb')

OPEN dbCursor

-- Fetch database name dau tien vao con tro va gan vao variable @DBname
FETCH NEXT FROM dbCursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Gan duong dan den file backup vao variable @backupFileName
	SET @backupFileName = @backupPath + @DBName + '.bak'
	-- Backup database, tao file su dung duong dan cua variable @backupFileNamee
	BACKUP DATABASE @DBName TO DISK = @backupFileName

	-- Fetch database name tiep theo vao con tro va gan vao variable @DBname
	FETCH NEXT FROM dbCursor INTO @DBName
END;

CLOSE dbCursor;

DEALLOCATE dbCursor;


-- Tat xp_cmdshell
EXECUTE sp_configure 'show advanced options', 0;  
GO  
RECONFIGURE;  
GO  