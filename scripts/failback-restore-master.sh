#!/bin/bash
set -e

echo "=========================================="
echo "ProxySQL Failback: Restore Original Master"
echo "=========================================="

# Variables (ajusta según tu .env)
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
PROXYSQL_CONTAINER="${PROXYSQL_CONTAINER:-db-proxy}"
ORIGINAL_MASTER="${ORIGINAL_MASTER:-db-master}"
CURRENT_MASTER="${CURRENT_MASTER:-db-slave}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-***REMOVED***}"
MYSQL_REPLICATION_USER="${MYSQL_REPLICATION_USER:-***REMOVED***}"
MYSQL_REPLICATION_PASSWORD="${MYSQL_REPLICATION_PASSWORD:-***REMOVED***}"

echo "Verificando estado actual de ProxySQL..."
docker exec $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
read -p "¿Confirmas failback de '$ORIGINAL_MASTER' como nuevo master? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado por usuario."
    exit 1
fi

echo ""
echo "Paso 1: Reconfigurando $ORIGINAL_MASTER como slave del master actual..."
# Obtener posición GTID del master actual
GTID_EXECUTED=$(docker exec $CURRENT_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null)

docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;

CHANGE MASTER TO
    MASTER_HOST='$CURRENT_MASTER',
    MASTER_PORT=3306,
    MASTER_USER='$MYSQL_REPLICATION_USER',
    MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD',
    MASTER_AUTO_POSITION=1,
    MASTER_SSL=1;

START SLAVE;
SHOW SLAVE STATUS\G
"

echo ""
echo "Esperando sincronización (30s)..."
sleep 30

echo ""
echo "Paso 2: Verificando replicación..."
SLAVE_STATUS=$(docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "
SELECT CONCAT('IO:', Slave_IO_Running, ' SQL:', Slave_SQL_Running, ' Lag:', Seconds_Behind_Master) 
FROM performance_schema.replication_connection_status 
JOIN performance_schema.replication_applier_status_by_worker 
LIMIT 1;
" 2>/dev/null || echo "ERROR")

echo "Estado de replicación: $SLAVE_STATUS"

if [[ $SLAVE_STATUS == *"IO:Yes SQL:Yes"* ]]; then
    echo "✅ Replicación activa"
else
    echo "❌ Replicación con problemas. Revisa: docker exec $ORIGINAL_MASTER mysql -uroot -p... -e 'SHOW SLAVE STATUS\G'"
    exit 1
fi

echo ""
read -p "¿Proceder con switchover (promover $ORIGINAL_MASTER a master)? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Failback parcial completado. $ORIGINAL_MASTER está como slave."
    exit 0
fi

echo ""
echo "Paso 3: Bloqueando escrituras en master actual ($CURRENT_MASTER)..."
docker exec $CURRENT_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;
FLUSH TABLES WITH READ LOCK;
"

sleep 5

echo ""
echo "Paso 4: Promoviendo $ORIGINAL_MASTER a master..."
docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL read_only=0;
SET GLOBAL super_read_only=0;
SHOW MASTER STATUS\G
"

echo ""
echo "Paso 5: Reconfigurando $CURRENT_MASTER como slave de $ORIGINAL_MASTER..."
GTID_NEW=$(docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null)

docker exec $CURRENT_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
UNLOCK TABLES;
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
    MASTER_HOST='$ORIGINAL_MASTER',
    MASTER_PORT=3306,
    MASTER_USER='$MYSQL_REPLICATION_USER',
    MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD',
    MASTER_AUTO_POSITION=1,
    MASTER_SSL=1;

START SLAVE;
SHOW SLAVE STATUS\G
"

echo ""
echo "Paso 6: Reconfigurando ProxySQL..."
docker exec $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
-- Restaurar original master a writer hostgroup (HG 10)
UPDATE mysql_servers 
SET hostgroup_id=10, status='ONLINE' 
WHERE hostname='$ORIGINAL_MASTER';

-- Mover actual master a reader hostgroup (HG 20)
UPDATE mysql_servers 
SET hostgroup_id=20, status='ONLINE' 
WHERE hostname='$CURRENT_MASTER' AND hostgroup_id=10;

-- Aplicar cambios
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Verificar configuración
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
echo "✅ Failback completado:"
echo "   - Master restaurado: $ORIGINAL_MASTER (hostgroup 10)"
echo "   - Slave: $CURRENT_MASTER (hostgroup 20)"
echo ""
echo "⚠️  Verificar:"
echo "   1. Conectividad de aplicaciones"
echo "   2. Replicación: docker exec $CURRENT_MASTER mysql -uroot -p... -e 'SHOW SLAVE STATUS\G'"
echo "   3. Logs ProxySQL: docker logs -f $PROXYSQL_CONTAINER"
echo "=========================================="
