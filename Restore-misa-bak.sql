-- Restore script test cho script Restore-database-from-timestamped-folder-v3.sql
DECLARE	@dirTable TABLE(dirFiles NVARCHAR(256))

INSERT INTO @dirTable
EXEC XP_CMDSHELL 'powershell -command "ls C:\27-10-2020\ -file | % { $_.basename }"'
SELECT * FROM @dirTable

DECLARE	@path NVARCHAR(256)
SET @path = 'C:\27-10-2020\'

DECLARE @fileName NVARCHAR(256),
		@filePath NVARCHAR(256),
		@filePathWithQuote NVARCHAR(256)	

DECLARE @ldfFile NVARCHAR(MAX),
		@mdfFile NVARCHAR(MAX),
		@ldfFilePath NVARCHAR(MAX),
		@mdfFilePath NVARCHAR(MAX),
		@ldfDataPath NVARCHAR(MAX),
		@mdfDataPath NVARCHAR(MAX)
SET @mdfDataPath = 'C:\test-restore-misa\data\'
SET	@ldfDataPath = 'C:\test-restore-misa\log\'

DECLARE dbCursor CURSOR
	FOR SELECT
		dirFiles
	FROM
		@dirTable
	WHERE
		dirFiles IS NOT NULL

OPEN dbCursor

FETCH NEXT FROM dbCursor INTO @fileName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @filePath = @path + @fileName + '.BAK'
	SET @filePathWithQuote = ('' + @filePath + '')

	SET @ldfFile = @ldfDataPath + @fileName + '.ldf'
	SET @ldfFilePath = ('' + @ldfFile + '')

	SET @mdfFile = @mdfDataPath + @fileName + 'mdf'
	SET @mdfFilePath = ('' + @mdfFile + '')

	RESTORE DATABASE @filename
		FROM DISK = @filePathWithQuote
		WITH MOVE 'MISASME2012' TO @mdfFilePath, 
		MOVE 'MISASME2012_log' TO @ldfFilePath,
		REPLACE, RECOVERY

	FETCH NEXT FROM dbCursor INTO @fileName
END

CLOSE dbCursor;

DEALLOCATE dbCursor;
