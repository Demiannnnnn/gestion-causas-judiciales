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
MYSQL_REPLICATION_USER="${MYSQL_REPLICATION_USER:-replicator}"
MYSQL_REPLICATION_PASSWORD="${MYSQL_REPLICATION_PASSWORD:-***REMOVED***}"

echo "Verificando estado actual de ProxySQL..."
docker exec $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
# Permitir modo automático con flag -y
if [[ "$1" != "-y" ]]; then
    read -p "¿Confirmas failback de '$ORIGINAL_MASTER' como nuevo master? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelado por usuario."
        exit 1
    fi
else
    echo "Modo automático: procediendo sin confirmación"
fi

echo ""
echo "Paso 1: Reconfigurando $ORIGINAL_MASTER como slave del master actual..."
# Obtener posición GTID del master actual
GTID_EXECUTED=$(docker exec $CURRENT_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null)

docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
STOP REPLICA;
RESET REPLICA ALL;
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='$CURRENT_MASTER',
    SOURCE_PORT=3306,
    SOURCE_USER='$MYSQL_REPLICATION_USER',
    SOURCE_PASSWORD='$MYSQL_REPLICATION_PASSWORD',
    SOURCE_AUTO_POSITION=1,
    SOURCE_SSL=1;

START REPLICA;
SHOW REPLICA STATUS\G
"

echo ""
echo "Esperando sincronización (30s)..."
sleep 30

echo ""
echo "Paso 2: Verificando replicación..."
SLAVE_STATUS=$(docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "
SELECT CONCAT('IO:', SERVICE_STATE, ' SQL:', LAST_ERROR_MESSAGE) 
FROM performance_schema.replication_connection_status 
LIMIT 1;
" 2>/dev/null || echo "ERROR")

echo "Estado de replicación: $SLAVE_STATUS"

if [[ $SLAVE_STATUS == *"IO:ON"* ]]; then
    echo "✅ Replicación activa"
else
    echo "❌ Replicación con problemas. Revisa: docker exec $ORIGINAL_MASTER mysql -uroot -p... -e 'SHOW REPLICA STATUS\G'"
    exit 1
fi

echo ""
# Permitir modo automático con flag -y
if [[ "$1" != "-y" ]]; then
    read -p "¿Proceder con switchover (promover $ORIGINAL_MASTER a master)? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Failback parcial completado. $ORIGINAL_MASTER está como slave."
        exit 0
    fi
else
    echo "Modo automático: procediendo con switchover"
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
STOP REPLICA;
RESET REPLICA ALL;
SET GLOBAL read_only=0;
SET GLOBAL super_read_only=0;
" 2>/dev/null
docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW MASTER STATUS\G" 2>/dev/null || echo "✓ Master promovido"

echo ""
echo "Paso 5: Reconfigurando $CURRENT_MASTER como slave de $ORIGINAL_MASTER..."
GTID_NEW=$(docker exec $ORIGINAL_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null)

docker exec $CURRENT_MASTER mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
UNLOCK TABLES;
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='$ORIGINAL_MASTER',
    SOURCE_PORT=3306,
    SOURCE_USER='$MYSQL_REPLICATION_USER',
    SOURCE_PASSWORD='$MYSQL_REPLICATION_PASSWORD',
    SOURCE_AUTO_POSITION=1,
    SOURCE_SSL=1;

START REPLICA;
SHOW REPLICA STATUS\G
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
echo "   2. Replicación: docker exec $CURRENT_MASTER mysql -uroot -p... -e 'SHOW REPLICA STATUS\G'"
echo "   3. Logs ProxySQL: docker logs -f $PROXYSQL_CONTAINER"
echo "=========================================="
