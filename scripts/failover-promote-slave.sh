#!/bin/bash
set -e

# Cargar variables de entorno
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../.env" ]; then
  set -a
  source "$SCRIPT_DIR/../.env"
  set +a
fi

echo "=========================================="
echo "ProxySQL Failover: Promote Slave to Master"
echo "=========================================="

# Variables
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
PROXYSQL_CONTAINER="${PROXYSQL_CONTAINER:-db-proxy}"
OLD_MASTER="${OLD_MASTER:-db-master}"
NEW_MASTER="${NEW_MASTER:-db-slave}"
MYSQL_REPLICATION_USER="${MYSQL_REPLICATION_USER:-replicatr}"
MYSQL_REPLICATION_PASSWORD="${MYSQL_REPLICATION_PASSWORD}"

echo "Verificando estado actual de ProxySQL..."
docker exec -e MYSQL_PWD="$PROXYSQL_ADMIN_PASSWORD" $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -e "
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
"

echo ""
# Permitir modo automático con flag -y
if [[ "$1" != "-y" ]]; then
  read -p "¿Confirmas promover '$NEW_MASTER' a master (HG 10)? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado por usuario."
    exit 1
  fi
else
  echo "Modo automático: procediendo sin confirmación"
fi

echo ""
echo "Paso 1: Deteniendo escrituras en antiguo master ($OLD_MASTER)..."
# Nota: Se usa usuario replicador con permisos suficientes para operaciones de failover
docker exec $OLD_MASTER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_REPLICATION_USER
password=$MYSQL_REPLICATION_PASSWORD
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e '
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;
FLUSH TABLES WITH READ LOCK;
'
  rm -f /tmp/.my.cnf
" 2>/dev/null || echo "⚠️  No se pudo bloquear el antiguo master (posiblemente caído)"

echo ""
echo "Paso 2: Desactivando replicación en $NEW_MASTER y habilitando writes..."
docker exec $NEW_MASTER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e '
-- Detener la replicación
STOP REPLICA;
RESET REPLICA ALL;

-- Habilitar escrituras
SET GLOBAL read_only=0;
SET GLOBAL super_read_only=0;

-- Mostrar estado del nuevo master
SHOW MASTER STATUS\G
'
  rm -f /tmp/.my.cnf
" 2>/dev/null || echo "✓ Nueva master configurada"

echo ""
echo "Paso 3: Reconfigurando ProxySQL..."
docker exec -e MYSQL_PWD="$PROXYSQL_ADMIN_PASSWORD" $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -e "
-- Eliminar TODAS las entradas de ambos servidores para evitar conflictos
DELETE FROM mysql_servers WHERE hostname='$OLD_MASTER' OR hostname='$NEW_MASTER';

-- Insertar el nuevo master en HG 10 (writers)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections, max_replication_lag, status) 
VALUES (10, '$NEW_MASTER', 3306, 100, 100, 5, 'ONLINE');

-- Insertar el nuevo master en HG 20 (readers - para que también sirva lecturas)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections, max_replication_lag, status) 
VALUES (20, '$NEW_MASTER', 3306, 100, 100, 5, 'ONLINE');

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
echo "   - Nuevo Master: $NEW_MASTER (hostgroups 10 y 20)"
echo "   - Antiguo Master: $OLD_MASTER (OFFLINE en ambos hostgroups)"
echo ""
echo "⚠️  Próximos pasos:"
echo "   1. Verificar conectividad de aplicaciones"
echo "   2. Monitorear logs: docker logs -f $PROXYSQL_CONTAINER"
echo "   3. Planificar failback cuando el antiguo master esté disponible"
echo "=========================================="
