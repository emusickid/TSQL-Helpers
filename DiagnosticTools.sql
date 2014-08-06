/*What's going on on the SQL Server???*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 
	DB_NAME(er.database_id) AS DBName,
	es.login_name,
	er.session_id,
	er.cpu_time,
	er.command,
	er.logical_reads,
	er.reads,
	st.text as SQLText,
	es.program_name,
	--DB_NAME(es.database_id) AS DatabaseName,
	'kill ' + CAST(er.session_id as VARCHAR(3)),
	er.percent_complete,
	er.estimated_completion_time/1000/60 AS EstimatedMinutesRemaining,
	er.estimated_completion_time
FROM
	sys.dm_exec_requests er
	INNER JOIN sys.dm_exec_sessions es ON er.session_id = es.session_id
	CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
--WHERE
----	er.cpu_time > 10
	--es.program_name = 'Eric''s Data Masker'
ORDER BY er.cpu_time DESC
/*Check Blocking*/
SELECT 
	er.session_id,
	st.text as SQLText,
	er.start_time,
	er.status,
	er.command,
	db1.name AS DBName,
	er.blocking_session_id,
	br.command,
	bst.text AS BlockingSQL,
	er.wait_resource,
	er.cpu_time,
	er.reads,
	er.writes,
	er.logical_reads
FROM 
	sys.dm_exec_requests er
	CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
	INNER JOIN sys.dm_exec_requests br ON er.blocking_session_id = br.session_id
	CROSS APPLY sys.dm_exec_sql_text(br.sql_handle) AS bst
	INNER JOIN sys.databases db1 ON er.database_id = db1.database_id
WHERE
	er.blocking_session_id > 0
ORDER BY DBName, er.reads 




/*Service Broker related Activity*/
SELECT
	t1.spid AS MainSPID,
	bat.procedure_name AS BrokerActivationProc,
	t1.waitresource AS MainWaitResource,
	db1.name AS MainDBName,
	t1.cpu AS MainCPU,
	t1.physical_io AS MainPhysicalIO,
	t1.open_tran AS MainOpenTran,
	t1.cmd AS MainCommand,
	t2.spid AS BlockerSPID,
	t2.waitresource AS BlockerWaitResource,
	db2.name AS BlockerDBName,
	t2.cpu AS BlockerCPU,
	t2.physical_io AS BlockerPhysicalIO,
	t2.open_tran AS BlockerOpenTran,
	t2.cmd AS BlockerCommand
FROM
	sys.dm_broker_activated_tasks bat
    INNER JOIN sys.sysprocesses t1 ON bat.spid = t1.spid
	LEFT JOIN sys.sysprocesses t2 ON t1.spid = t2.blocked
	INNER JOIN sys.databases db1 ON t1.dbid = db1.database_id
	INNER JOIN sys.databases db2 ON t2.dbid = db2.database_id
--WHERE
--      t1.blocked >0
ORDER BY t1.spid

SELECT * FROM sys.dm_broker_activated_tasks

SELECT * FROM sys.dm_tran_locks WHERE request_session_id = 107


/*View Page Latching*/

31:1:20084
SELECT DB_ID()

DBCC TRACEOFF(3604)
GO

SELECT * FROM sys.indexes WHERE object_id = object_id('trade')

SELECT * from dbo.trade

DBCC IND ('dbname', 'dbo.tableName', 1) 

DBCC PAGE('dbname',1,77024,0) WITH TABLERESULTS /*DBID, fileid, pagenumber)*/
GO

/*Clear Wait Stats

DBCC SQLPERF ('sys.dm_os_latch_stats', CLEAR);
GO
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);


CHECKPOINT;
DBCC freeproccache
DBCC FREESYSTEMCACHE ('all')
DBCC DROPCLEANBUFFERS

*/

SELECT * FROM sys.dm_os_latch_stats WHERE latch_class = 'BUFFER'
GO
SELECT * FROM sys.dm_os_wait_stats WHERE wait_type LIKE '%PAGELATCH%'



SELECT OBJECT_NAME(597577167)

/*Transaction Locks*/
SELECT
	db.name, 
	tl.*,
	er.*,
	st.*
FROM 
	sys.dm_tran_locks tl
	INNER JOIN sys.databases db ON tl.resource_database_id = database_id
	INNER JOIN sys.dm_exec_requests er ON tl.request_session_id = er.session_id
	CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
WHERE
	db.name = DB_NAME()


DBCC OPENTRAN

/*Waits*/

SELECT * FROM sys.dm_os_wait_stats ORDER BY wait_time_ms DESC

SELECT 
	er.session_id, 
	wt.wait_duration_ms, 
	er.cpu_time, 
	er.logical_reads, 
	st.text 
FROM 
	sys.dm_os_waiting_tasks  wt
	INNER JOIN sys.dm_exec_requests er ON wt.session_id = er.session_id
	CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
ORDER BY er.cpu_time DESC


/*Fragmentation Stats*/
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.tableName'), NULL, NULL , NULL);


SELECT 
	db.name AS DataBaseName,
	stats.object_id, 
	tables.name AS TableName,
	ix.index_id, 
	ix.name AS IndexName,
	avg_fragmentation_in_percent,
	ghost_record_count,
	avg_page_space_used_in_percent,
	page_count,
	record_count
FROM 
	sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbName.dbo.table'), NULL, NULL, NULL) stats
	INNER JOIN sys.databases db ON stats.database_id = db.database_id
	INNER JOIN sys.tables tables ON stats.object_id = tables.object_id
	INNER JOIN sys.indexes ix ON tables.object_id = ix.object_id AND stats.index_id = ix.index_id

SELECT
	t1.object_id,
	OBJECT_NAME(t1.object_id) AS ObjectName,
	t2.fill_factor,
	t2.name,
	index_type_desc,
	avg_fragmentation_in_percent,
	avg_record_size_in_bytes,
	'ALTER INDEX ALL ON dbo.' + OBJECT_NAME(t1.object_id) + ' REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON); RAISERROR (N''Indexes rebuilt succesfully on ' + OBJECT_NAME(t1.object_id) + ''', 10, 1, 1) WITH NOWAIT;' AS RebuildScript
FROM 
	sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) t1
	INNER JOIN sys.indexes t2 ON t1.object_id = t2.object_id AND t1.index_id = t2.index_id
WHERE
	avg_fragmentation_in_percent > 20
ORDER BY 6 DESC


/* Rebuild Indexes
ALTER INDEX ALL ON dbo.ngposition REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON);
GO
*/


/*Plan Cache Shiz*/

SELECT 
	'Procedure
	Cache Allocated',
	CONVERT(int,((CONVERT(numeric(10,2),cntr_value)* 8192)/1024)/1024) as 'MBs'
from master.dbo.sysperfinfo
where object_name = 'SQLServer:Buffer Manager' and
counter_name = 'Procedure cache pages'
UNION
SELECT 'Buffer Cache database pages',
CONVERT(int,((CONVERT(numeric(10,2),cntr_value)
* 8192)/1024)/1024)
as 'MBs'
from master.dbo.sysperfinfo
where object_name = 'SQLServer:Buffer Manager' and
counter_name = 'Database pages'
UNION
SELECT 'Free pages',
CONVERT(int,((CONVERT(numeric(10,2), cntr_value)
* 8192)/1024)/1024)
as 'MBs'
from master.dbo.sysperfinfo
where object_name = 'SQLServer:Buffer Manager' and
counter_name = 'Free pages' 

GO


DBCC freeproccache
SELECT
	st.*, 
	cp.* 
FROM 
	sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
ORDER BY cp.usecounts DESC

SELECT 
	[text], 
	cp.size_in_bytes, 
	cp.usecounts,
	cp.refcounts,
	plan_handle
FROM 
	sys.dm_exec_cached_plans AS cp
	CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE 
	cp.cacheobjtype = N'Compiled Plan'
	AND cp.objtype = N'Adhoc'
	AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC;


SELECT 
	SUM((CAST(cp.size_in_bytes AS BIGINT))) AS TotalBytes 
FROM 
	sys.dm_exec_cached_plans AS cp
	CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE 
	cp.cacheobjtype = N'Compiled Plan'
	AND cp.objtype = N'Adhoc'
	AND cp.usecounts = 1

sp_readerrorlog

xp_fixeddrives


/*IO by DB*/
SELECT
    d.Name							AS DatabaseName,
    COUNT(c.connection_id)			AS NumberOfConnections,
    ISNULL(SUM(c.num_reads), 0)		AS NumberOfReads,
    ISNULL(SUM(c.num_writes), 0)	AS NumberOfWrites
FROM sys.databases d
LEFT JOIN sys.sysprocesses s ON s.dbid = d.database_id
LEFT JOIN sys.dm_exec_connections c ON c.session_id = s.spid
WHERE (s.spid IS NULL OR c.session_id >= 51)
GROUP BY d.Name



/*Flush SQL Server Memory*/

CHECKPOINT;
DBCC freeproccache
DBCC FREESYSTEMCACHE ('all')
DBCC DROPCLEANBUFFERS

EXEC sp_updatestats
UPDATE STATISTICS dbo.ngquantityNew WITH FULLSCAN
UPDATE STATISTICS dbo.ngpositionNew WITH FULLSCAN
UPDATE STATISTICS dbo.positionNew WITH FULLSCAN

/*Misc*/

SELECT * FROM sys.databases
WAITFOR DELAY '00:00:01:000'

SELECT DB_ID()


/*Page Life Expectancy*/
SELECT 
	[object_name],
	[counter_name],
	[cntr_value]
FROM 
	sys.dm_os_performance_counters
WHERE 
	[object_name] LIKE '%Manager%'
	AND [counter_name] = 'Page life expectancy'





SELECT  @@servername AS INSTANCE
,[object_name]
,[counter_name]
, UPTIME_MIN = CASE WHEN[counter_name]= 'Page life expectancy'
          THEN (SELECT DATEDIFF(MI, MAX(login_time),GETDATE())
          FROM   master.sys.sysprocesses
          WHERE  cmd='LAZY WRITER')
      ELSE ''
END
, [cntr_value] AS PLE_SECS
,[cntr_value]/ 60 AS PLE_MINS
,[cntr_value]/ 3600 AS PLE_HOURS
,[cntr_value]/ 86400 AS PLE_DAYS
FROM  sys.dm_os_performance_counters
WHERE   [object_name] LIKE '%Manager%'
          AND[counter_name] = 'Page life expectancy'



/*Extended Events*/
CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'E:\sqlxevents\blocked_process.xel',
     metadatafile = N'E:\sqlxevents\blocked_process.xem',
     max_file_size=(65536),
     max_rollover_files=5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO

EXEC sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO
/* Enabled the blocked process report */
EXEC sp_configure 'blocked process threshold', '5';
RECONFIGURE
GO
/* Start the Extended Events session */
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = START;


GO
-- Extended Event for finding *long running query*
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='LongRunningQuery')
DROP EVENT SESSION LongRunningQuery ON SERVER
GO
-- Create Event
CREATE EVENT SESSION LongRunningQuery
ON SERVER
-- Add event to capture event
ADD EVENT sqlserver.sql_statement_completed
(
-- Add action - event property
ACTION (sqlserver.sql_text, sqlserver.tsql_stack)
-- Predicate - time 1000 milisecond
WHERE sqlserver.sql_statement_completed.duration > 1000
)
-- Add target for capturing the data - XML File
ADD TARGET package0.asynchronous_file_target(
SET filename='E:\sqlxevents\LongRunningQuery.xel', metadatafile='E:\sqlxevents\LongRunningQuery.xem'),
-- Add target for capturing the data - Ring Bugger
ADD TARGET package0.ring_buffer
(SET max_memory = 4096)
WITH (max_dispatch_latency = 1 seconds)
GO
-- Enable Event
ALTER EVENT SESSION LongRunningQuery ON SERVER
STATE=START
GO

GO

--Extended Event for Deprcated Features
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='find_deprecation_final_support')
	DROP EVENT SESSION LongRunningQuery ON SERVER
GO
CREATE EVENT SESSION [find_deprecation_final_support] ON SERVER
ADD EVENT sqlserver.deprecation_final_support 
ADD TARGET package0.ring_buffer
WITH (MAX_DISPATCH_LATENCY=3 SECONDS)
GO
ALTER EVENT SESSION [find_deprecation_final_support]
ON SERVER
STATE=START
GO

--Test Depricated Events

USE MASTER
GO
ALTER DATABASE cs_9131_seminole_uat_apr23 SET COMPATIBILITY_LEVEL = 90
GO

SET ROWCOUNT 100;

CREATE TABLE #temp (id INT IDENTITY, msg TEXT)
INSERT INTO #temp  SELECT('this is a test')
SELECT * FROM #temp


GO
WAITFOR DELAY '00:00:05';
GO

DECLARE @xml_holder XML;
SELECT @xml_holder = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
    ON t.event_session_address = s.address
WHERE s.name = N'find_deprecation_final_support'
  AND t.target_name = N'ring_buffer';
SELECT
   node.value('(data[@name="feature_id"]/value)[1]', 'int')as feature_id,
      node.value('(data[@name="feature"]/value)[1]', 'varchar(50)')as feature,
         node.value('(data[@name="message"]/value)[1]', 'varchar(200)')as message,
    node.value('(@name)[1]', 'varchar(50)') AS event_name
FROM @xml_holder.nodes('RingBufferTarget/event') AS p(node);



/**Backup DB*/
DECLARE @backupfilename SYSNAME = N'E:\dbbackups\cs_9131_seminole_bpc3_apr28.bak'
DECLARE @bakupsetname SYSNAME = N'qa_valcompare_calpine-Full Database Backup'

BACKUP DATABASE qa_valcompare_calpine_current TO  
DISK = @backupfilename WITH NOFORMAT, 
INIT,  
NAME = @bakupsetname, SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10

GO

/**Resore DB*/
USE [master]

RESTORE DATABASE [QA_Calpine_GR2014 ]
FROM DISK = N'E:\dbbackups\db.bak'
WITH FILE = 1
	,MOVE N'allegro_gold' TO N'path.mdf'
	,MOVE N'allegro_gold_log' TO N'path.ldf'
	,MOVE N'allegro_gold_log2' TO N'path.ldf'
	,NOUNLOAD
	,REPLACE
	,STATS = 5

GO

/*Get Table Size*/
SELECT 
    s.Name AS SchemaName,
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 4 DESC


/*Table to FileGroup Mapping*/
SELECT 
	o.[name]
	,o.[type]
	,i.[name]
	,i.[index_id]
	,f.[name]
FROM 
	sys.indexes i
	INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
	INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id]
WHERE 
	i.data_space_id = f.data_space_id
	AND o.type = 'U'
GO