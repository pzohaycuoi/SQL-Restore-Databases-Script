-- 17/10/2020 Nguyen Hoang Nam
-- Script phan quyen databases cho users
-- Phuc vu phan quyen cho database asoft, su dung manually

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

-- @dbs: variable chua database
-- @command: variable chua sql's sp phan quyena
DECLARE @dbs NVARCHAR(1000),
		@command NVARCHAR(1000);

-- tao cursor tro den tung database khong thuoc trong danh sach tai WHERE		
DECLARE dbcursor CURSOR FOR
	SELECT	name
	FROM	sys.databases
	WHERE	name NOT IN ('master','tempdb','model','msdb','AACC_HN',
			'VINATAX','VINATAX_BK','VINATAX_CG','VINATAX_HN','VINATAX1',
			'VINATAX2');

OPEN dbcursor

-- Fetch database dau tien vao con tro
FETCH NEXT FROM dbcursor INTO @dbs

WHILE @@FETCH_STATUS = 0
BEGIN
	-- variable su dung database hien tai con tro dang cam va phan quyen db_datareader va db_datawriter cho [users]
	SELECT	@command = 'USE ' + @dbs + ';' +
			'EXEC sp_addrolemember N''db_datareader'',[sa];
			EXEC sp_addrolemember N''db_datawriter'',[sa];
			EXEC sp_addrolemember N''db_owner'',[sa]'

	-- execute @command sp
	EXEC	sp_executesql @command 
	
	FETCH NEXT FROM dbcursor INTO @dbs
END

CLOSE dbcursor
DEALLOCATE dbcursor

-- Tat xp_cmdshell
EXECUTE sp_configure 'show advanced options', 0;  
GO  
RECONFIGURE;  
GO  