--Extended Event for Deprcated Features
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='find_deprecation_final_support')
	DROP EVENT SESSION LongRunningQuery ON SERVER
GO
CREATE EVENT SESSION [find_deprecation_final_support] ON SERVER
ADD EVENT sqlserver.deprecation_final_support 
ADD TARGET package0.ring_buffer
WITH (MAX_DISPATCH_LATENCY=3 SECONDS)
GO
--Start/Stop Event
ALTER EVENT SESSION [find_deprecation_final_support]
ON SERVER
STATE=START --STOP
GO

--Query Event Info
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

