-- Restore script test cho script Restore-database-from-timestamped-folder-v3.sql
DECLARE	@dirTable TABLE(dirFiles NVARCHAR(256))

INSERT INTO @dirTable
EXEC XP_CMDSHELL 'powershell -command "ls E: -file | % { $_.basename }"'

DECLARE	@path NVARCHAR(256)
SET @path = 'E:\'

DECLARE @fileName NVARCHAR(256),
		@filePath NVARCHAR(256),
		@filePathWithQuote NVARCHAR(256)

DECLARE @ldfFile NVARCHAR(MAX),
		@mdfFile NVARCHAR(MAX),
		@ldfFilePath NVARCHAR(MAX),
		@mdfFilePath NVARCHAR(MAX),
		@dataPath NVARCHAR(MAX)
SET @dataPath = 'E:\MSSQL\MSSQL15.MSSQLSERVER\MSSQL\DATA\'

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

	SET @ldfFile = @dataPath + @fileName + '.ldf'
	SET @ldfFilePath = ('' + @ldfFile + '')

	SET @mdfFile = @dataPath + @fileName + 'mdf'
	SET @mdfFilePath = ('' + @mdfFile + '')

	RESTORE DATABASE @filename
		FROM DISK = @filePathWithQuote
		WITH MOVE 'CONGTY' TO @mdfFilePath, 
		MOVE 'CONGTY_log' TO @ldfFilePath,
		REPLACE

	FETCH NEXT FROM dbCursor INTO @fileName
END

CLOSE dbCursor;

DEALLOCATE dbCursor;
