#!/bin/bash

echo "=========================================="
echo "Database Replication Health Check"
echo "=========================================="

# Cargar variables de entorno
if [ -f "$(dirname "$0")/../.env" ]; then
    set -a
    source "$(dirname "$0")/../.env"
    set +a
fi

MYSQL_MONITOR_USER="${MYSQL_MONITOR_USER:-monitor_user}"
MYSQL_MONITOR_PASSWORD="${MYSQL_MONITOR_PASSWORD:-***REMOVED***}"
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
MYSQL_MASTER_HOST="${MYSQL_MASTER_HOST:-db-master}"
MYSQL_SLAVE_HOST="${MYSQL_SLAVE_HOST:-db-slave}"
PROXYSQL_CONTAINER="${PROXYSQL_CONTAINER:-db-proxy}"

echo ""
echo "=== ProxySQL Server Status ==="
docker exec -e MYSQL_PWD="$PROXYSQL_ADMIN_PASSWORD" $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -e "
SELECT hostgroup_id, hostname, port, status, weight, max_connections
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
" 2>/dev/null

echo ""
echo "=== ProxySQL Connection Pool ==="
docker exec -e MYSQL_PWD="$PROXYSQL_ADMIN_PASSWORD" $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -e "
SELECT hostgroup, srv_host, status, ConnUsed, ConnFree, ConnOK, ConnERR, Queries, Latency_us
FROM stats_mysql_connection_pool
ORDER BY hostgroup, srv_host;
" 2>/dev/null

echo ""
echo "=== DB Master Status ==="
if docker ps --format '{{.Names}}' | grep -q "^${MYSQL_MASTER_HOST}$"; then
    docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MYSQL_MASTER_HOST mysql -u$MYSQL_MONITOR_USER -e "
SELECT @@hostname AS hostname, @@server_id AS server_id, @@read_only AS read_only, @@super_read_only AS super_read_only;
SHOW MASTER STATUS;
" 2>/dev/null || echo "⚠️  $MYSQL_MASTER_HOST está corriendo pero no responde a queries"
else
    echo "❌ $MYSQL_MASTER_HOST no está corriendo (failover esperado)"
fi

echo ""
echo "=== DB Slave Replication Status ==="
if docker ps --format '{{.Names}}' | grep -q "^${MYSQL_SLAVE_HOST}$"; then
    docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MYSQL_SLAVE_HOST mysql -u$MYSQL_MONITOR_USER -e "
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
" 2>/dev/null || echo "⚠️  $MYSQL_SLAVE_HOST está corriendo pero no responde a queries"
else
    echo "❌ $MYSQL_SLAVE_HOST no está corriendo"
fi

echo ""
echo "=== GTID Status ==="
echo "Master GTID:"
if docker ps --format '{{.Names}}' | grep -q "^${MYSQL_MASTER_HOST}$"; then
    docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MYSQL_MASTER_HOST mysql -u$MYSQL_MONITOR_USER -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | head -c 80 || echo "(no disponible)"
else
    echo "(contenedor caído)"
fi
echo "..."
echo ""
echo "Slave GTID:"
if docker ps --format '{{.Names}}' | grep -q "^${MYSQL_SLAVE_HOST}$"; then
    docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MYSQL_SLAVE_HOST mysql -u$MYSQL_MONITOR_USER -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | head -c 80 || echo "(no disponible)"
else
    echo "(contenedor caído)"
fi
echo "..."

echo ""
echo "=========================================="
