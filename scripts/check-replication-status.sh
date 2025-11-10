#!/bin/bash

echo "=========================================="
echo "Database Replication Health Check"
echo "=========================================="

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-***REMOVED***}"
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"

echo ""
echo "=== ProxySQL Server Status ==="
docker exec db-proxy mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
SELECT hostgroup_id, hostname, port, status, weight, max_connections
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
" 2>/dev/null

echo ""
echo "=== ProxySQL Connection Pool ==="
docker exec db-proxy mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
SELECT hostgroup, srv_host, status, ConnUsed, ConnFree, ConnOK, ConnERR, Queries, Latency_us
FROM stats_mysql_connection_pool
ORDER BY hostgroup, srv_host;
" 2>/dev/null

echo ""
echo "=== DB Master Status ==="
docker exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
SELECT @@hostname AS hostname, @@server_id AS server_id, @@read_only AS read_only, @@super_read_only AS super_read_only;
SHOW MASTER STATUS;
" 2>/dev/null || echo "❌ db-master no responde"

echo ""
echo "=== DB Slave Replication Status ==="
docker exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
SELECT @@hostname AS hostname, @@server_id AS server_id, @@read_only AS read_only, @@super_read_only AS super_read_only;
SELECT 
    CHANNEL_NAME,
    SERVICE_STATE,
    SOURCE_HOST,
    SOURCE_PORT,
    LAST_ERROR_MESSAGE,
    LAST_ERROR_TIMESTAMP
FROM performance_schema.replication_connection_status;

SELECT 
    CHANNEL_NAME,
    SERVICE_STATE,
    LAST_ERROR_MESSAGE,
    LAST_ERROR_TIMESTAMP
FROM performance_schema.replication_applier_status_by_worker;
" 2>/dev/null || echo "❌ db-slave no responde"

echo ""
echo "=== GTID Status ==="
echo "Master GTID:"
docker exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | head -c 80
echo "..."
echo ""
echo "Slave GTID:"
docker exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | head -c 80
echo "..."

echo ""
echo "=========================================="
