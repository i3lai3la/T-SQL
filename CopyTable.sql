CREATE PROCEDURE copySchema(@schemaName NVARCHAR(MAX), @srcDb NVARCHAR(MAX), @dstDb NVARCHAR(MAX))
AS

DECLARE @trans_name VARCHAR(20);
SET @trans_name='MoveSrcs';
BEGIN TRANSACTION @trans_name

CREATE TABLE #tableNames (
	schemaName		NVARCHAR(100),
	tableName		NVARCHAR(100)
);

DECLARE @sql            NVARCHAR(MAX);
DECLARE @schemaName NVARCHAR(MAX);
DECLARE	@srcDb NVARCHAR(MAX);
DECLARE @dstDb NVARCHAR(MAX);

SET @schemaName = '14';
SET @srcDb = 'srcdb';/* name your source db*/
SET @dstDb = 'dstdb';/* name your destination db*/
SET @sql = '
	INSERT #tableNames(schemaName,tableName)
	(
		SELECT s.name, t.name
		FROM    (SELECT * FROM ['+@srcDb+'].sys.schemas WHERE schemas.name='''+@schemaName+''') s
			INNER JOIN ['+@srcDb+'].sys.tables t ON s.schema_id=t.schema_id
	)
'
PRINT @sql
EXEC sp_executesql @sql;

DECLARE @schema_name    NVARCHAR(100);
DECLARE @table_name     NVARCHAR(100);
DECLARE table_cursor CURSOR FOR
    SELECT schemaName, tableName
    FROM   #tableNames;
OPEN table_cursor;

FETCH next FROM table_cursor INTO @schema_name, @table_name;

WHILE (@@fetch_status=0)
BEGIN
    SET @sql='SELECT * INTO "'+@dstDb+'"."'+@schema_name+'"."'+@table_name+'" FROM "'+@srcDb+'"."'+@schema_name+'"."'+@table_name+'"';

    PRINT @sql;
    exec sp_executesql @sql;

    FETCH next FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

DROP TABLE #tableNames;

COMMIT TRANSACTION @trans_name;
