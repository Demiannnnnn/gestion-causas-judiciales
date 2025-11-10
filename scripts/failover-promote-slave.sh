#!/bin/bash
set -e

echo "=========================================="
echo "ProxySQL Failover: Promote Slave to Master"
echo "=========================================="

# Variables (ajusta según tu .env)
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
PROXYSQL_CONTAINER="${PROXYSQL_CONTAINER:-db-proxy}"
OLD_MASTER="${OLD_MASTER:-db-master}"
NEW_MASTER="${NEW_MASTER:-db-slave}"

echo "Verificando estado actual de ProxySQL..."
docker exec $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
read -p "¿Confirmas promover '$NEW_MASTER' a master (HG 10)? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado por usuario."
    exit 1
fi

echo ""
echo "Paso 1: Deteniendo escrituras en antiguo master ($OLD_MASTER)..."
docker exec db-master mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-***REMOVED***}" -e "
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;
FLUSH TABLES WITH READ LOCK;
" 2>/dev/null || echo "⚠️  No se pudo bloquear el antiguo master (posiblemente caído)"

echo ""
echo "Paso 2: Promoviendo $NEW_MASTER a master..."
docker exec db-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-***REMOVED***}" -e "
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL read_only=0;
SET GLOBAL super_read_only=0;
SHOW MASTER STATUS\G
"

echo ""
echo "Paso 3: Reconfigurando ProxySQL..."
docker exec $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASSWORD -e "
-- Mover antiguo master a reader hostgroup (HG 20)
UPDATE mysql_servers 
SET hostgroup_id=20, status='OFFLINE_HARD' 
WHERE hostname='$OLD_MASTER';

-- Mover nuevo master a writer hostgroup (HG 10)
UPDATE mysql_servers 
SET hostgroup_id=10, status='ONLINE' 
WHERE hostname='$NEW_MASTER' AND hostgroup_id=20;

-- Aplicar cambios
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Verificar configuración
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
echo "✅ Failover completado:"
echo "   - Nuevo Master: $NEW_MASTER (hostgroup 10)"
echo "   - Antiguo Master: $OLD_MASTER (hostgroup 20, OFFLINE)"
echo ""
echo "⚠️  Próximos pasos:"
echo "   1. Verificar conectividad de aplicaciones"
echo "   2. Monitorear logs: docker logs -f $PROXYSQL_CONTAINER"
echo "   3. Planificar failback cuando el antiguo master esté disponible"
echo "=========================================="
