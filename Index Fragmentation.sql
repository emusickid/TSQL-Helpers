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