-- 20/10/2020 16:51 Nguyen Hoang Nam 
-- Script restore databases tu file full-backup, 
-- su dung cung voi cmd or powershell ket hop task-scheduler tren primary server
-- Phuc vu cho Backup Server (or secondary server): Tu dong restore database len secondary server
--------------------------------------------------------------------------------------

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

-- Set path chua timestamped folder duoc tao ra tu script Create-Timestamped-and-full-backup.sql
DECLARE @cmdShellCommand nvarchar(MAX) = 'EXEC XP_CMDSHELL ''dir D:\Test-DBs\Backup /A:D /O-D /4'''

CREATE TABLE #tempStoredDirTable (
	lineID int identity
	,pureData nvarchar(MAX)
)
INSERT INTO #tempStoredDirTable
	EXEC (@cmdShellCommand)

-- @dirTable3Columns temptable de loc @#tempStoredDirTable thanh du lieu su dung duoc
DECLARE @dirTable3Columns TABLE (
	fileID int identity
	,createdDate datetime
	,filePath nvarchar(MAX)
)
-- @dirTable3Columns cat du lieu tu @#tempStoredDirTable thanh dung form dung columns
INSERT INTO @dirTable3Columns
	SELECT
		CONVERT(Datetime,(left(pureData, 20))) CreateDate,
		FilePath2.FilePath + '\' + right(pureData,LEN(pureData)-39) Filename
	FROM #tempStoredDirTable
	CROSS APPLY (
	SELECT
		MAX(LineID) LineID
    FROM #tempStoredDirTable FilePaths
	WHERE 
		LEFT(pureData,14)=' Directory of '
		and FilePaths.LineID < #tempStoredDirTable.LineID) FilePath1
	JOIN (
	SELECT
		LineID, 
		RIGHT(pureData, LEN(pureData)-14
	) FilePath
    FROM #tempStoredDirTable FilePaths
    WHERE LEFT(pureData,14)=' Directory of '
	) FilePath2
ON FilePath1.LineID = FilePath2.LineID
WHERE ISDATE(left(pureData, 20))=1
ORDER BY 1

DROP TABLE #tempStoredDirTable

-- get rid of these things from #tempStoredDirTable
DELETE FROM @dirTable3Columns
WHERE RIGHT(filePath, 2) = '..' OR RIGHT(filePath, 1) = '.';

-- @folderPath tao path vao ben trong folder backup
DECLARE @folderPath nvarchar(MAX) = (
	SELECT TOP 
		1 filePath
	FROM 
		@dirTable3Columns 
	ORDER BY createdDate DESC
) + '\'

-- @cmdDirBackupFolder lenh cmd dir lay list file .bak ben trong folder backup
DECLARE @cmdDirBackupFolder nvarchar(MAX) = N'EXEC XP_CMDSHELL ''dir ' +  @folderPath + N' /b'''


-- @dirBackupFolder table chua ten file trong folder backup
DECLARE @dirBackupFolder table(dirFiles nvarchar(MAX))
INSERT INTO @dirBackupFolder
	EXEC (@cmdDirBackupFolder)
UPDATE @dirBackupFolder SET dirFiles = REPLACE(dirFiles, RIGHT(dirFiles, 4), '')

-- Set path chua file mdf va ldf here
DECLARE @fileName nvarchar(MAX)
		,@bakfilePath nvarchar(MAX)
		,@mdfFolderPath nvarchar(MAX) = 'D:\Test-DBs\mdf-file\'
		,@ldfFolderPath nvarchar(MAX) = 'D:\Test-DBs\ldf-file\'
		,@mdffilePath nvarchar(MAX)
		,@ldffilePath nvarchar(MAX)

DECLARE bakFileCursor CURSOR
	FOR SELECT
		dirFiles
	FROM
		@dirBackupFolder
	WHERE
		dirFiles IS NOT NULL

OPEN bakFileCursor

FETCH NEXT FROM bakFileCursor INTO @fileName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @bakfilePath = '' + @folderPath + @fileName + '.bak'
	SET @mdffilePath = '' + @mdfFolderPath + @fileName + '.mdf'''
	SET @ldffilePath = '' + @ldfFolderPath + @fileName + '.ldf'''

	CREATE TABLE #FileListHeaders (     
		 LogicalName nvarchar(128)
		,PhysicalName nvarchar(260)
		,[Type] char(1)
		,FileGroupName nvarchar(128) NULL
		,Size numeric(20,0)
		,MaxSize numeric(20,0)
		,FileID bigint
		,CreateLSN numeric(25,0)
		,DropLSN numeric(25,0) NULL
		,UniqueID uniqueidentifier
		,ReadOnlyLSN numeric(25,0) NULL
		,ReadWriteLSN numeric(25,0) NULL
		,BackupSizeInBytes bigint
		,SourceBlockSize int
		,FileGroupID int
		,LogGroupGUID uniqueidentifier NULL
		,DifferentialBaseLSN numeric(25,0) NULL
		,DifferentialBaseGUID uniqueidentifier NULL
		,IsReadOnly bit
		,IsPresent bit
	)
	IF cast(cast(SERVERPROPERTY('ProductVersion') as char(4)) as float) > 9
	BEGIN
		ALTER TABLE #FileListHeaders ADD TDEThumbprint varbinary(32) NULL
	END
	IF cast(cast(SERVERPROPERTY('ProductVersion') as char(2)) as float) > 12
	BEGIN
		ALTER TABLE #FileListHeaders ADD SnapshotURL nvarchar(360) NULL
	END

	DECLARE @whatIsThisShit nvarchar(MAX) = 'RESTORE FILELISTONLY FROM DISK = ''' + @bakfilePath + ''''
	INSERT INTO #FileListHeaders
		EXEC(@whatisThisShit)

	DECLARE @dataLogicalName nvarchar(MAX) = (SELECT LogicalName FROM #FileListHeaders WHERE Type = 'D')
			,@logLogicalName nvarchar(MAX) = (SELECT LogicalName FROM #FileListHeaders WHERE Type = 'L')
	SET @dataLogicalName = '' + @dataLogicalName + ''
	SET @logLogicalName = '' + @logLogicalName + ''

	DROP TABLE #FileListHeaders

	-- 21/10/2020 18:31 Nguyen Hoang Nam: Xem xet thay doi ham RESTORE thanh REPLACE RESTORE de replace Database 
	-- 22/10/2020 11:33 Nguyen Hoang Nam: Su dung WITH MOVE de move ldf+mdf file sang location moi va REPLACE de thay Database da exist trong sys.database
	-- Can phai check SQL version cua database voi SQL version cua Instance
	RESTORE DATABASE @fileName
		FROM DISK = @bakfilePath
		
		-- RESTORE database se can phai move file mdf va log file sang path moi
		WITH MOVE @dataLogicalName TO @mdffilePath,
		MOVE @logLogicalName TO @ldffilePath,
		REPLACE, NOUNLOAD, STATS = 20

	FETCH NEXT FROM bakFileCursor INTO @fileName
END;

CLOSE bakFileCursor;

DEALLOCATE bakFileCursor;

-- Tat xp_cmdshell
EXECUTE sp_configure 'show advanced options', 0;  
GO  
RECONFIGURE;  
GO