#!/bin/bash

#[ $(id -u) gt 0] && echo "Please log in as the root user!" && exit

### 服务器信息 ###
mysql_info(){
	mysql_ab=/usr/local/mysql/bin/mysql
	mysql_cmd='-uroot -hlocalhost -p123456'
}

### 连通性测试 ###
connect(){
	$mysql_ab $mysql_cmd -e "show global variables like'123';" 2>/dev/null || exit
}
### 服务器型号 ###
server_version(){
	echo "系统基本信息巡检"
	echo "服务器型号"
	echo "+----------------+"
	echo "| Server_version |"
	echo "+-----------------"
	cat /var/log/dmesg | grep 'DMI:' | sed 's/^/| /'
	echo "+-----------------"
}

### CPU型号 ###
cpu_version(){
	echo "CPU型号"
	echo "+-------------+";
	echo "| CPU_version |";
	echo "+--------------";
	cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq | sed 's/^/| /' 
	echo "+--------------"
}

### CPU核数 ###
cpu_core(){
	echo "CPU核数"
	echo "+----------+"
	echo "| CPU_core |"
	echo "+----------+"
	cpu_c=`lscpu | grep '^CPU(s)'|awk '{print $2}'`
	echo "| $cpu_c       |"
	echo "+----------+"
	#cat /proc/cpuinfo| grep "processor"| wc -l
}

### 硬盘空间 ###
disk(){
	echo "硬盘空间"
	#df -H |awk "{OFS=\"\t\"}{ print \$1,\$2,\$3,\$4,\$5,\$6}"
	echo "+------------------------------------------------------------------------+"
	echo "| Disk                             "
	echo "+------------------------------------------------------------------------+"
	df -H | sed 's/^/| /' 
	echo "+------------------------------------------------------------------------+"
}

### 系统版本 ###
os_version(){
	echo -e "系统版本"
	echo "+------------+"
	echo "| OS_version |"
	echo "+------------+"
	cat /etc/redhat-release &>/dev/null
	if (($?==0))
	then
		cat /etc/redhat-release | sed 's/^/| /'
	else
		cat /etc/issue | sed 's/^/| /'
	fi
	echo "+------------+"
}


### MySQL版本 ###
mysql_version(){
	echo "数据库基本信息巡检"
	echo -e "MySQL版本"
	v_1="select @@version;"
	$mysql_ab $mysql_cmd -N -e "${v_1}"  2>/dev/null
}
### MySQL端口号 ###
mysql_port(){
	echo -e "MySQL端口号"
        mp_1="show global variables like 'port';"
        $mysql_ab $mysql_cmd -N -e"${mp_1}" 2>/dev/null
}

### MySQL位置 ###
mysql_basedir(){
	echo -e "MySQL basedir"
	myb_1="show global variables like 'basedir';"
	$mysql_ab $mysql_cmd -N -e"${myb_1}" 2>/dev/null
}

mysql_datadir(){
	echo -e "MySQL datadir"
	myd_1="show global variables like 'datadir';"
	$mysql_ab $mysql_cmd -N -e"${myd_1}" 2>/dev/null
}

### MySQL进程数 ###
mysql_processnum(){
	echo -e "MySQL进程数"
	MYSQL_PROCESSNUM=`ps -ef|grep "mysql"|grep -v "grep"|wc -l`
	echo "+----------------+"
	echo "| Process number |"
	echo "+----------------+"
	echo "| ${MYSQL_PROCESSNUM}              |"
	echo "+----------------+"
	echo
	echo "分析：MySQL进程数无异常"
}

### MySQL表已用空间 ###
mysql_table_total(){
	echo -e "MySQL表已用空间"
        mtt_1="select concat(round(sum(DATA_LENGTH/1024/1024),2),'MB') as DATA_TOTAL from information_schema.TABLES;"
        $mysql_ab $mysql_cmd -e "${mtt_1}" 2>/dev/null
	echo
	echo "分析：MySQL表已用空间正常，磁盘压力很小"
}

### MySQL每个库已用 ###
mysql_database_total(){
	echo -e "MySQL各个库的空间使用情况"
	mdt="SELECT TABLE_SCHEMA,round(SUM(data_length+index_length)/1024/1024,2) AS TOTAL_MB,round(SUM(data_length)/1024/1024,2) AS DATA_MB,round(SUM(index_length)/1024/1024,2) AS INDEX_MB,COUNT(*) AS TABLES FROM information_schema.tables GROUP BY table_schema ORDER BY 2 DESC;"
	$mysql_ab $mysql_cmd -e "${mdt}" 2>/dev/null
	echo
	echo "分析：MySQL表空间正常"
}

### MySQL binlog ###
mysql_log_bin(){
	echo -e "MySQL binlog"
	$mysql_ab $mysql_cmd -N -e "show global variables like 'log_bin%';" 2>/dev/null
	echo
	echo "分析：Binlog设置正常"
}

### MySQL慢日志 ###
mysql_slow_log(){
	echo -e "MySQL慢日志"
	$mysql_ab $mysql_cmd -N -e "show global variables like 'slow_query%';show global variables like 'log_queries%';show global variables like 'long_query_time%';" 2>/dev/null
	echo
	echo "分析：慢日志设置正常"
}

### 日志报警级别 ###
log_warning(){
	echo "日志报警相关"
        logw_1="show global variables like '%log_warnings%';"
        $mysql_ab $mysql_cmd -N -e"${logw_1}" 2>/dev/null
        echo
	echo "分析：日志报警级别建议设置为2"
}

### binlog日志保留天数 ###
binlog_expire_days(){
	echo "binlog日志保留天数"
	bed="show global variables like '%expire_logs_days%';"
	$mysql_ab $mysql_cmd -N -e"${bed}" 2>/dev/null
	echo
	echo "分析：binlog日志保留天数正常"
	echo
}

### 内存命中率 ###

### InnoDB Buffer命中率 ###
# Innodb_buffer_read_hits = (1 - innodb_buffer_pool_reads / innodb_buffer_pool_read_requests) * 100%
innodb_buffer_read(){
	innob_1="show global status like 'Innodb_buffer_pool_reads'; "
	innob_2="show global status like 'Innodb_buffer_pool_read_requests'; "
	uptime=`$mysql_ab $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	ibp_reads=`$mysql_ab $mysql_cmd -e"${innob_1}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ibp_reads_re=`$mysql_ab $mysql_cmd -e"${innob_2}" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo "MySQL重要监控项巡检"
	echo "内存命中率"
	echo "+--------------------+"
	echo "| Innodb_buffer_hits |"
	echo "+--------------------+"
	if [ "${ibp_reads}" -eq 0  ]
	then
		echo "| null"
	else
		#innob_3=`awk 'BEGIN{print '${ibp_reads}' / '${ibp_reads_re}'}'`
		#innob_4=`awk 'BEGIN{print '1-${innob_3}'}'`
		#innodb_buffer_read_hits=`awk 'BEGIN{print '${innob_4}' * 100}'`
		innodb_buffer_read_hits=`awk 'BEGIN{print (1- ('${ibp_reads}' / '${ibp_reads_re}')) * 100}'`
		echo "| ${innodb_buffer_read_hits:0:5}%"
	fi
	echo "+--------------------+"
	echo
}

### Key Buffer命中率 ###
# key_buffer_read_hits = (1-key_reads / key_read_requests) * 100%
key_buffer_read(){
	kbrd_1="show global status like 'Key_reads'; "
	kbrd_2="show global status like 'Key_read_requests'; "
	uptime=`$mysql_ab $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	key_reads=`$mysql_ab $mysql_cmd -e"${kbrd_1}" 2>/dev/null|grep -v Variable_name|cut -f 2`
	key_reads_re=`$mysql_ab $mysql_cmd -e"${kbrd_2}" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo "+-----------------+"
	echo "| Key_buffer_hits |"
	echo "+-----------------+"
	if [ "${key_reads}" -lt 10 ]
	then
		echo "| null"
	else
		kbrd_3=`awk 'BEGIN{print '${key_reads}' / '${key_reads_re}'}'`
		kbrd_4=`awk 'BEGIN{print '1-${kbrd_3}'}'`
		key_buffer_read_hits=`awk 'BEGIN{print '${kbrd_4}' * 100}'`
		echo "| ${key_buffer_read_hits:0:5}%"
	fi
	echo "+-----------------+"
	echo
}

### table_cache_hits ###
table_cache_hits(){
	uptime=`$mysql_ab $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	open_t=`$mysql_ab $mysql_cmd -e"show global status like 'Open_tables%';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	opened_t=`$mysql_ab $mysql_cmd -e"show global status like 'Opened_tables%';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo "+------------------+"
	echo "| Table_cache_hits |"
	echo "+------------------+"
	if [ ${opened_t} -eq 0 ]
	then
		echo "| null"
	else
		tch1=`awk 'BEGIN{print '${open_t}' / '${opened_t}'}'`
		tch2=`awk 'BEGIN{print '${tch1}' * 100}'`
		echo "| ${tch2:0:5}%"
	fi
	echo "+------------------+"
	echo
	echo "分析：内存命中率较高，性能较好"
}

### 磁盘相关 ###
disk_mem(){
	echo "磁盘相关"
	$mysql_ab $mysql_cmd -N -e"show global status like 'created_tmp%';" 2>/dev/null
	uptime=`$mysql_ab $mysql_cmd -e"show global status like 'uptime';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	ctdt=`$mysql_ab $mysql_cmd -e"show global status like 'Created_tmp_disk_tables';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ctt=`$mysql_ab $mysql_cmd -e"show global status like 'Created_tmp_tables';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo
	echo "+-----------------------+"
	echo "| Memory_tmp_tables_pct |"
	echo "+-----------------------+"
#	if [ "${uptime}" -lt 10800 ]
#	then
#		echo "Memory_tmp_tables_pct:null"
	if [ "${ctt}" -eq 0  ]
	then
		echo "| null"
	else
		mttp=`awk 'BEGIN{print (100 - (( '${ctdt}' / '${ctt}' ) * 100))}'`
		echo "| ${mttp:0:5}%"
	fi
	echo "+-----------------------+"
	echo
	$mysql_ab $mysql_cmd -N -e"show global status like 'binlog_cache%';" 2>/dev/null
	bcdu=`$mysql_ab $mysql_cmd -e"show global status like 'binlog_cache_disk_use';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	bcu=`$mysql_ab $mysql_cmd -e"show global status like 'binlog_cache_use';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo
	echo "+----------------------+"
	echo "| Binlog_cache_use_pct |"
	echo "+----------------------+"
	if [ "${bcu}" -eq 0 ]
	then
		echo "| null"
	else
		bcup=`awk 'BEGIN{print (100 - ('${bcdu}' / ('${bcu}' + 1) * 100))}'`
		echo "| ${bcup:0:5}%"
	fi
	echo "+----------------------+"
	echo
	echo "分析：所有临时表中创建内存表的比例较高，Binlog日志缓存使用率正常，性能较好"
}

### MyISAM表锁相关 ###
myisam(){
	echo "MyISAM表锁相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'table_locks_%';" 2>/dev/null
	tli=`$mysql_ab $mysql_cmd -e"show global status like 'table_locks_immediate';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	tlw=`$mysql_ab $mysql_cmd -e"show global status like 'table_locks_waited';" 2>/dev/null|grep -v Variable_name|cut -f 2`
	echo
	echo "+----------------------+"
	echo "| Table_lock_condition |"
	echo "+----------------------+"
	if [ "${tli}" -eq 0 ]
	then
		echo "| null" 
	else
		tlc=`awk 'BEGIN{print ('${tlw}' / ('${tli}' + '${tlw}' )) * 100}'`
		echo "| ${tlc:0:5}%"
	fi
	echo "+----------------------+"
	echo
	echo "分析：MyISAM表锁状态良好"
}

### 行锁相关 ###
row_lock(){
	echo "行锁相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_row_lock%';" 2>/dev/null
	echo
	echo "分析：行锁状态良好"
}

### Innodb buffer pool相关 ###
innodb_bp(){
	echo "Innodb buffer pool相关"
	$mysql_ab $mysql_cmd -N -e"show global status like 'innodb_buffer_pool_w%';" 2>/dev/null
	ibpwf=`$mysql_ab $mysql_cmd -e"show global status like 'innodb_buffer_pool_wait_free';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ibpwr=`$mysql_ab $mysql_cmd -e"show global status like 'innodb_buffer_pool_write_requests';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	echo
	echo "+-----------------------------------+"
	echo "| Innodb_buffer_pool_write_capacity |"
	echo "+-----------------------------------+"
	if [ "${ibpwr}" -eq 0 ]
	then
		echo "| null"
	else
		ibpwc=`awk 'BEGIN{print (100 - ( '$ibpwf' / '$ibpwr' )* 100)}'`
		echo "| ${ibpwc:0:5}%"
	fi
	echo "+-----------------------------------+"
	echo
	echo "分析：InnoDB缓冲池写入能力良好"
}

### redo log相关 ###
redo_log(){
	echo "redo log相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_log%';" 2>/dev/null
	echo
	echo "+-----------------------+"
	echo "| redo_log_write_stress |"
	echo "+-----------------------+"
	ilw1=`$mysql_ab $mysql_cmd -e "show global status like 'innodb_log_waits%';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	ilw2=`$mysql_ab $mysql_cmd -e "show global status like 'innodb_log_writes%';" 2>/dev/null |grep -v Variable_name |cut -f 2`
	rlws=`awk 'BEGIN{print (100 * ( '$ilw1' / ( '$ilw2' + 1 )))}'`
	echo "| ${rlws:0:5}"
	echo "+-----------------------+"
	echo
	echo "分析：redolog写压力正常"
}

### 线程、连接相关 ###
thread_connect(){
	echo "线程、连接相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'thread%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global status like '%connections';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global variables like 'max_connections';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global variables like 'thread_cache_size%';" 2>/dev/null
	echo
	echo "+--------------------+"
	echo "| threads_cache_hits |"
	echo "+--------------------+"
	tc=`$mysql_ab $mysql_cmd -e "show global status like 'Threads_created%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	conn=`$mysql_ab $mysql_cmd -e "show global status like 'connections%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	max_conn=`$mysql_ab $mysql_cmd -e "show global variables like '%max_connections%';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	tch=`awk 'BEGIN{print (100 - (( '${tc}' / '${conn}' ) * 100))}'`
	echo "| ${tch:0:5}%"
	echo "+--------------------+"
	echo
	echo "分析：线程缓存命中率较高，创建线程数量正常，连接数正常"
}

### 查询相关 ###
select1(){
	echo "查询相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'select%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global status like '%Handler_read%';" 2>/dev/null
	echo
	echo "+--------------------+"
	echo "| index_not_used_pct |"
	echo "+--------------------+"
	hrrn=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_rnd_next';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrr=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_rnd';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrf=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_first';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrn=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_next';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrk=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_key';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	hrp=`$mysql_ab $mysql_cmd -e "show global status like 'Handler_read_prev';" 2>/dev/null |grep -v Variable_name | cut -f 2`
	inup=`awk 'BEGIN{print (100 - (( '${hrrn}' + '${hrr}' ) / ( '${hrrn}' + '${hrr}' + '${hrf}' + '${hrn}' + '${hrk}' + '${hrp}' )) * 100)}'`
	hrr1=`awk 'BEGIN{print ( '${hrrn}' + '${hrr}' + '${hrf}' + '${hrn}' + '${hrk}' + '${hrp}' )}'`
	if [ "${hrr1}" -eq 0 ]
	then
		echo "| null"
	else
		echo "| ${inup:0:5}%"
	fi
	echo "+--------------------+"
	echo
	echo "分析：索引利用率正常"
}

### 排序相关 ###
sort1(){
	echo "排序相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'sort%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global variables like 'sort%';" 2>/dev/null
	echo
	echo "分析：排序次数正常，sort buffer设置合理"
}

### 行记录 ###
innodb_rows(){
	echo "InnoDB健康状况巡检"
	echo "行记录"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_rows_%';" 2>/dev/null
	echo
	echo "分析：SQL在InnoDB中的执行能力较好"
}

### InnoDB文件IO相关 ###
innodb_io(){
	echo "InnoDB文件IO"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_data_read%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_data_writ%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_pages_%';" 2>/dev/null
	echo
	echo "分析：InnoDB吞吐量正常"
}

### InnoDB磁盘刷新相关 ###
innodb_flush(){
	echo "InnoDB磁盘刷新相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_data_fsyncs%';" 2>/dev/null
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_data_pending%';" 2>/dev/null
	echo
	echo "分析：InnoDB磁盘刷新情况正常"
}

### innodb buffer pool使用状态 ###
innodb_use(){
	echo "innodb buffer pool使用状态"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_buffer_pool_pages%';" 2>/dev/null
	echo
	echo "分析：InnoDB缓冲池使用状态正常"
}

### redo log磁盘刷新相关 ###
redo_flush(){
	echo "redo log磁盘刷新相关"
	$mysql_ab $mysql_cmd -N -e "show global status like 'innodb_os_log_%';" 2>/dev/null
	echo
	echo "分析：redo log磁盘刷新状况正常"
}

main(){
	mysql_info
	connect
	server_version
	cpu_version
	cpu_core
	disk
	os_version
	mysql_version
	mysql_port
	mysql_basedir
	mysql_datadir
	mysql_processnum
	mysql_table_total
	mysql_database_total
	mysql_log_bin
	mysql_slow_log
	log_warning
	binlog_expire_days
	innodb_buffer_read
	key_buffer_read
	table_cache_hits
	disk_mem
	myisam
	row_lock
	innodb_bp
	redo_log
	thread_connect
	select1
	sort1
	innodb_rows
	innodb_io
	innodb_flush
	innodb_use
	redo_flush
}

echo "Start checking!"
echo "......"
main
echo "Checking completed!"


