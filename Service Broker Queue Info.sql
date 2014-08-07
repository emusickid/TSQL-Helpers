--Get Service Broker Queue Info
SELECT *, GETDATE() FROM (
SELECT
	--Servicename = s.name,
	--'ALTER QUEUE ' + sq.name + ' WITH ACTIVATION (STATUS = ON, MAX_QUEUE_READERS = 16);' AS AlterScript,
	QueueName             = sq.name,
    IsActivationEnabled   = is_activation_enabled,
    MaxReaders            = max_readers,
    ActivationProc        = activation_procedure,
    IsReceiveEnabled     = is_receive_enabled, 
    --IsEnqeueEnabled   = is_enqueue_enabled, 
    --IsRetentionEnabled  = is_retention_enabled,
    ISNULL((SELECT 
                p.rows 
            FROM 
				sys.internal_tables as it
				INNER JOIN sys.indexes as i on i.object_id = it.object_id and i.index_id = 1 
				INNER JOIN sys.partitions as p on p.object_id = i.object_id and p.index_id = i.index_id
            WHERE 
                sq.object_id = it.parent_id AND 
                it.parent_minor_id = 0 AND 
                it.internal_type = 201), 0) AS [RowCount]--,
	--COALESCE(ms.SendsPerSec, 0) AS SendsPerSec,
	--COALESCE(ms.ReceivesPerSec, 0) AS ReceivesPerSec
 FROM
	sys.service_queues AS sq
	INNER JOIN sys.services s ON sq.object_id = s.service_queue_id
	INNER JOIN sys.objects AS obj ON obj.type='SQ' AND sq.object_id=obj.object_id
	INNER JOIN sys.schemas AS ss ON ss.schema_id = sq.schema_id
	--LEFT JOIN dbo.MessageStatistics ms ON s.name COLLATE Latin1_General_BIN = ms.ServiceName
WHERE
    sq.is_ms_shipped = 0
) AS X
WHERE
	X.[RowCount] > 10
	--AND IsActivationEnabled = 0