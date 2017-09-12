select '数据库基本信息巡检' as ''\G
select @@version as 'MySQL版本!'\G
select @@port as 'MySQL端口号!'\G
select @@basedir as 'MySQL basedir!'\G
select @@datadir as 'MySQL datadir!'\G
select concat(round(sum(DATA_LENGTH/1024/1024),2),'MB') as 'MySQL表已用空间!' from information_schema.TABLES\G
SELECT table_schema AS '空间使用情况',SUM(data_length+index_length)/10 AS '总用量(MB)',SUM(data_length)/1024/1024 AS 'data用量(MB)',SUM(index_length)/1024/1024 AS 'index用量(MB)',COUNT(*) AS '表数量(个)' FROM information_schema.tables GROUP BY table_schema ORDER BY 2 DESC;
select '空间使用正常，磁盘压力很小' as '分析'\G
select * from information_schema.global_variables where Variable_name='log_bin' union all select * from information_schema.global_variables where Variable_name like 'slow_query%' union all select * from information_schema.global_variables where Variable_name like 'long_query_time%' union all select * from information_schema.global_variables where Variable_name like 'log_warnings%';
select 'MySQL重要监控项巡检' as ''\G
select '内存命中率' as ''\G
select VARIABLE_VALUE into @innodb_buffer_pool_reads from information_schema.global_status where VARIABLE_NAME =  'innodb_buffer_pool_reads';
select VARIABLE_VALUE into @innodb_buffer_pool_read_requests from information_schema.global_status where VARIABLE_NAME =  'innodb_buffer_pool_read_requests';
select concat(truncate((1-@innodb_buffer_pool_reads/@innodb_buffer_pool_read_requests)*100,2),'%')as "Innodb_buffer_hits!"\G
select VARIABLE_VALUE into @key_reads from information_schema.global_status where VARIABLE_NAME ='key_reads';
select VARIABLE_VALUE into @key_read_requests from information_schema.global_status where VARIABLE_NAME ='key_read_requests';
select concat(truncate((1-@key_reads/@key_read_requests)*100,2),'%')as 'Key_buffer_hits!'\G
select VARIABLE_VALUE into @Open_tables from information_schema.global_status where VARIABLE_NAME ='Open_tables';
select VARIABLE_VALUE into @Opened_tables from information_schema.global_status where VARIABLE_NAME ='Opened_tables';
select concat(truncate((@Open_tables/@Opened_tables)*100,2),'%')as 'Table_cache_hits!'\G
select '内存命中率较高，性能较好' as '分析'\G
select '磁盘相关' as ''\G
select VARIABLE_VALUE into @Created_tmp_disk_tables from information_schema.global_status where VARIABLE_NAME ='Created_tmp_disk_tables';
select VARIABLE_VALUE into @Created_tmp_tables from information_schema.global_status where VARIABLE_NAME ='Created_tmp_tables';
select concat(truncate((1-@Created_tmp_disk_tables/@Created_tmp_tables)*100,2),'%')as 'Memory_tmp_tables_pct!'\G
select VARIABLE_VALUE into @binlog_cache_disk_use from information_schema.global_status where VARIABLE_NAME ='binlog_cache_disk_use';
select VARIABLE_VALUE into @binlog_cache_use from information_schema.global_status where VARIABLE_NAME ='binlog_cache_use';
select concat(truncate((1-@binlog_cache_disk_use/@binlog_cache_use)*100,2),'%')as 'Binlog_cache_use_pct!'\G
select '所有临时表中创建内存表的比例较高，Binlog日志缓存使用率正常，性能较好' as '分析'\G
select 'MyISAM表锁相关' as ''\G
select VARIABLE_VALUE into @table_locks_immediate from information_schema.global_status where VARIABLE_NAME ='table_locks_immediate';
select VARIABLE_VALUE into @table_locks_waited from information_schema.global_status where VARIABLE_NAME ='table_locks_waited';
select concat(truncate(@table_locks_waited/(@table_locks_immediate+@table_locks_immediate)*100,2),'%')as 'Table_lock_condition!'\G
select 'MyISAM表锁状态良好' as '分析'\G
select '行锁相关' as ''\G
select * from information_schema.global_status where VARIABLE_NAME like 'innodb_row_lock%';
select '' as '分析'\G
select 'Innodb buffer pool相关' as ''\G
select VARIABLE_VALUE into @innodb_buffer_pool_wait_free from information_schema.global_status where VARIABLE_NAME ='innodb_buffer_pool_wait_free';
select VARIABLE_VALUE into @innodb_buffer_pool_write_requests from information_schema.global_status where VARIABLE_NAME ='innodb_buffer_pool_write_requests';
select concat(truncate((1-@innodb_buffer_pool_wait_free/@innodb_buffer_pool_write_requests)*100,2),'%')as 'Innodb_buffer_pool_write_capacity!'\G
select '' as '分析'\G
select 'redo log相关' as ''\G
select VARIABLE_VALUE into @innodb_log_waits from information_schema.global_status where VARIABLE_NAME ='innodb_log_waits';
select VARIABLE_VALUE into @innodb_log_writes from information_schema.global_status where VARIABLE_NAME ='innodb_log_writes';
select concat(truncate((@innodb_log_waits/(@innodb_log_writes+1))*100,2),'%')as 'redo_log_write_stress!'\G
select 'redolog写压力正常' as '分析'\G
select '线程、连接相关' as ''\G
select * from information_schema.global_status where VARIABLE_NAME like 'thread%' or VARIABLE_NAME like '%connections' union all select * from information_schema.global_variables where VARIABLE_NAME like 'max_connections' or VARIABLE_NAME like 'thread_cache_size%';
select VARIABLE_VALUE into @Threads_created from information_schema.global_status where VARIABLE_NAME ='Threads_created';
select VARIABLE_VALUE into @connections from information_schema.global_status where VARIABLE_NAME ='connections';
select concat(truncate((1-@Threads_created/@connections)*100,2),'%')as 'threads_cache_hits!'\G
select '线程缓存命中率较高，创建线程数量正常，连接数正常' as '分析'\G
select '查询相关' as ''\G
select VARIABLE_VALUE into @Handler_read_rnd_next from information_schema.global_status where VARIABLE_NAME ='Handler_read_rnd_next';
select VARIABLE_VALUE into @Handler_read_rnd from information_schema.global_status where VARIABLE_NAME ='Handler_read_rnd';
select VARIABLE_VALUE into @Handler_read_first from information_schema.global_status where VARIABLE_NAME ='Handler_read_first';
select VARIABLE_VALUE into @Handler_read_next from information_schema.global_status where VARIABLE_NAME ='Handler_read_next';
select VARIABLE_VALUE into @Handler_read_key from information_schema.global_status where VARIABLE_NAME ='Handler_read_key';
select VARIABLE_VALUE into @Handler_read_prev from information_schema.global_status where VARIABLE_NAME ='Handler_read_prev';
select concat(truncate((1-(@Handler_read_rnd_next+@Handler_read_rnd)/(@Handler_read_rnd_next+@Handler_read_rnd+@Handler_read_first+@Handler_read_next+@Handler_read_key+@Handler_read_prev))*100,2),'%')as 'index_not_used_pct!'\G
select '索引利用率正常' as '分析'\G
select '排序相关' as ''\G
select * from information_schema.global_status where VARIABLE_NAME like 'sort%' union all select * from information_schema.global_variables where VARIABLE_NAME like 'sort%';
select '排序次数正常，sort buffer设置合理' as '分析'\G