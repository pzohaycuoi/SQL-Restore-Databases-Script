-- cho chạy cursor sử dụng scripts này dựa trên table dir list bak file từ folder backup files
-- check note 27-10-2020: hiện tại đang sử dụng 2 cursor để lặp qua 2 table lấy dữ liệu và insert vào 2 temptable: rút gọn xuống 1 cursor only và 2 temptable xử lý dữ liệu
-- Tối ưu hóa script cho bớt lằng nhằng, xem xét thay thế temptable1 bằng variable
-- store logical data và log vào temptable có vẻ hợp lý, thêm 1 column database name thì vòng lặp sẽ bớt phức tạp hơn
-- Kết hợp với script restore database from time stamped folder: nên xem lại script đó có thể tối ưu hơn được nữa

CREATE TABLE #FileListHeaders (     
     LogicalName    nvarchar(128)
    ,PhysicalName   nvarchar(260)
    ,[Type] char(1)
    ,FileGroupName  nvarchar(128) NULL
    ,Size   numeric(20,0)
    ,MaxSize    numeric(20,0)
    ,FileID bigint
    ,CreateLSN  numeric(25,0)
    ,DropLSN    numeric(25,0) NULL
    ,UniqueID   uniqueidentifier
    ,ReadOnlyLSN    numeric(25,0) NULL
    ,ReadWriteLSN   numeric(25,0) NULL
    ,BackupSizeInBytes  bigint
    ,SourceBlockSize    int
    ,FileGroupID    int
    ,LogGroupGUID   uniqueidentifier NULL
    ,DifferentialBaseLSN    numeric(25,0) NULL
    ,DifferentialBaseGUID   uniqueidentifier NULL
    ,IsReadOnly bit
    ,IsPresent  bit
)
IF cast(cast(SERVERPROPERTY('ProductVersion') as char(4)) as float) > 9 -- Greater than SQL 2005 
BEGIN
    ALTER TABLE #FileListHeaders ADD TDEThumbprint  varbinary(32) NULL
END
IF cast(cast(SERVERPROPERTY('ProductVersion') as char(2)) as float) > 12 -- Greater than 2014
BEGIN
    ALTER TABLE #FileListHeaders ADD SnapshotURL    nvarchar(360) NULL
END
DECLARE @b nvarchar(max) = 'D:\Test-DBs\Backup\29-10-2020\AAA.bak'
DECLARE @a nvarchar(max) = 'RESTORE FILELISTONLY FROM DISK = N''' + @b + ''''
PRINT @a
INSERT INTO #FileListHeaders
EXEC (@a)

SELECT * FROM #FileListHeaders

DECLARE @mdf nvarchar(MAX) = (SELECT LogicalName FROM #FileListHeaders WHERE Type = 'D')
DECLARE @ldf nvarchar(MAX) = (SELECT LogicalName FROM #FileListHeaders WHERE Type = 'L')

SELECT @mdf
SELECT @ldf

DROP TABLE #FileListHeaders