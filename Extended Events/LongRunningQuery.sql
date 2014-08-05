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