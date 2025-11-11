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
echo "ProxySQL Failback: Restore Original Master"
echo "=========================================="

# Variables
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
PROXYSQL_CONTAINER="${PROXYSQL_CONTAINER:-db-proxy}"
ORIGINAL_MASTER="${ORIGINAL_MASTER:-db-master}"
CURRENT_MASTER="${CURRENT_MASTER:-db-slave}"
MYSQL_REPLICATION_USER="${MYSQL_REPLICATION_USER:-replicaor}"
MYSQL_REPLICATION_PASSWORD="${MYSQL_REPLICATION_PASSWORD}"
MYSQL_ROOT_USER="${MYSQL_ROOT_USER:-root}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"

# Función helper para ejecutar queries MySQL de forma segura
mysql_exec() {
  local container=$1
  local user=$2
  local password=$3
  local query=$4
  
  docker exec $container bash -c "
    cat > /tmp/.my.cnf << EOF
[client]
user=$user
password=$password
EOF
    chmod 600 /tmp/.my.cnf
    mysql --defaults-extra-file=/tmp/.my.cnf -NB $5 <<< '$query'
    rm -f /tmp/.my.cnf
  "
}

echo "Verificando estado actual de ProxySQL..."
docker exec $PROXYSQL_CONTAINER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=$PROXYSQL_ADMIN_USER
password=$PROXYSQL_ADMIN_PASSWORD
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -h127.0.0.1 -P6032 -e '
SELECT hostgroup_id, hostname, status 
FROM mysql_servers 
ORDER BY hostgroup_id, hostname;
'
  rm -f /tmp/.my.cnf
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
GTID_EXECUTED=$(docker exec $CURRENT_MASTER bash -c "
  cat > /tmp/.my.cnf << 'CNFEOF'
[client]
user=$MYSQL_REPLICATION_USER
password=$MYSQL_REPLICATION_PASSWORD
host=127.0.0.1
CNFEOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -NB -e 'SELECT @@GLOBAL.gtid_executed;'
  rm -f /tmp/.my.cnf
" 2>/dev/null)

docker exec $ORIGINAL_MASTER bash -c "
  cat > /tmp/.my.cnf << 'CNFEOF'
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
CNFEOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e \"
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
\"
  rm -f /tmp/.my.cnf
"

echo ""
echo "Esperando sincronización (30s)..."
sleep 30

echo "Paso 2: Verificando replicación..."
SLAVE_STATUS=$(docker exec $ORIGINAL_MASTER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -NB -e '
SELECT CONCAT(\"IO:\", SERVICE_STATE, \" SQL:\", LAST_ERROR_MESSAGE) 
FROM performance_schema.replication_connection_status 
LIMIT 1;
'
  rm -f /tmp/.my.cnf
" 2>/dev/null || echo "ERROR")

echo "Estado de replicación: $SLAVE_STATUS"

if [[ $SLAVE_STATUS == *"IO:ON"* ]]; then
  echo "✅ Replicación activa"
else
  echo "❌ Replicación con problemas. Revisa: docker exec $ORIGINAL_MASTER bash -c 'cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
EOF
mysql --defaults-extra-file=/tmp/.my.cnf -e \"SHOW REPLICA STATUS\G\"; rm -f /tmp/.my.cnf'"
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
echo "Paso 3: Esperando sincronización completa del $ORIGINAL_MASTER..."
# Verificar que el original master esté completamente sincronizado
MAX_WAIT=120
WAIT_COUNT=0
SYNC_CONFIRMED=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  # Obtener GTIDs de ambos lados
  CURRENT_GTID=$(docker exec -e MYSQL_PWD="$MYSQL_ROOT_USER" $CURRENT_MASTER mysql -u root -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | tr -d '\n' || echo "")
  ORIGINAL_GTID=$(docker exec -e MYSQL_PWD="$MYSQL_ROOT_USER" $ORIGINAL_MASTER mysql -u root -NB -e "SELECT @@GLOBAL.gtid_executed;" 2>/dev/null | tr -d '\n' || echo "")
  
  # Verificar estado de replicación
  BEHIND=$(docker exec $ORIGINAL_MASTER bash -c "
    cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_REPLICATION_USER
password=$MYSQL_REPLICATION_PASSWORD
host=127.0.0.1
EOF
    chmod 600 /tmp/.my.cnf
    mysql --defaults-extra-file=/tmp/.my.cnf -NB -e '
        SELECT COALESCE(
            (SELECT COUNT(*) FROM performance_schema.replication_applier_status_by_worker 
             WHERE LAST_ERROR_NUMBER != 0), 0
        ) + COALESCE(
            (SELECT IF(SECONDS_BEHIND_SOURCE IS NULL OR SECONDS_BEHIND_SOURCE = 0, 0, 1)
             FROM performance_schema.replication_connection_status LIMIT 1), 0
        ) as issues;
'
    rm -f /tmp/.my.cnf
  " 2>/dev/null || echo "1")

  if [ "$BEHIND" = "0" ] && [ "$CURRENT_GTID" = "$ORIGINAL_GTID" ]; then
    ((SYNC_CONFIRMED++))
    echo "✅ Sincronización confirmada ($SYNC_CONFIRMED/2)"
    if [ $SYNC_CONFIRMED -ge 2 ]; then
      echo "✅ $ORIGINAL_MASTER está completamente sincronizado con GTIDs idénticos"
      break
    fi
  else
    SYNC_CONFIRMED=0
    echo "Esperando sincronización... ($WAIT_COUNT/$MAX_WAIT)"
    if [ -n "$CURRENT_GTID" ] && [ -n "$ORIGINAL_GTID" ]; then
      echo "  Current Master GTID (primeros 100 chars): ${CURRENT_GTID:0:100}"
      echo "  Original Master GTID (primeros 100 chars): ${ORIGINAL_GTID:0:100}"
    fi
  fi
  
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 2))
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
  echo "⚠️  ADVERTENCIA: Timeout esperando sincronización"
  echo "GTIDs pueden no ser idénticos. Revisa replicación antes de continuar:"
  echo "  docker exec $ORIGINAL_MASTER mysql -u root -p -e \"SHOW REPLICA STATUS\G\""
  read -p "¿Continuar de todas formas? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Failback cancelado"
    exit 1
  fi
fi

echo ""
echo "Paso 4: Esperando que se completen todas las transacciones pendientes..."
sleep 10

echo ""
echo "Paso 5: Bloqueando escrituras en master actual ($CURRENT_MASTER)..."
docker exec $CURRENT_MASTER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e '
SET GLOBAL read_only=1;
SET GLOBAL super_read_only=1;
FLUSH TABLES WITH READ LOCK;
'
  rm -f /tmp/.my.cnf
"

echo "Esperando 10s para asegurar que todas las transacciones se replicaron..."
sleep 10

echo ""
echo "Paso 6: Promoviendo $ORIGINAL_MASTER a master..."
docker exec $ORIGINAL_MASTER bash -c "
  cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
EOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e '
STOP REPLICA;
RESET REPLICA ALL;
SET GLOBAL read_only=0;
SET GLOBAL super_read_only=0;
'
  mysql --defaults-extra-file=/tmp/.my.cnf -e 'SHOW MASTER STATUS\G'
  rm -f /tmp/.my.cnf
" 2>/dev/null || echo "✓ Master promovido"

echo ""
echo "Paso 7: Reconfigurando $CURRENT_MASTER como slave de $ORIGINAL_MASTER..."
GTID_NEW=$(docker exec $ORIGINAL_MASTER bash -c "
  cat > /tmp/.my.cnf << 'CNFEOF'
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
CNFEOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -NB -e 'SELECT @@GLOBAL.gtid_executed;'
  rm -f /tmp/.my.cnf
" 2>/dev/null)

docker exec $CURRENT_MASTER bash -c "
  cat > /tmp/.my.cnf << 'CNFEOF'
[client]
user=$MYSQL_ROOT_USER
password=$MYSQL_ROOT_PASSWORD
host=127.0.0.1
CNFEOF
  chmod 600 /tmp/.my.cnf
  mysql --defaults-extra-file=/tmp/.my.cnf -e \"
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
\"
  rm -f /tmp/.my.cnf
"

echo ""
echo "Esperando que la replicación se estabilice..."
sleep 5

echo ""
echo "Paso 8: Reconfigurando ProxySQL..."
docker exec -e MYSQL_PWD="$PROXYSQL_ADMIN_PASSWORD" $PROXYSQL_CONTAINER mysql -h127.0.0.1 -P6032 -u$PROXYSQL_ADMIN_USER -e "
-- Eliminar TODAS las entradas antiguas
DELETE FROM mysql_servers WHERE hostname='$ORIGINAL_MASTER' OR hostname='$CURRENT_MASTER';

-- Restaurar original master como writer (HG 10)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections, max_replication_lag, status) 
VALUES (10, '$ORIGINAL_MASTER', 3306, 100, 100, 5, 'ONLINE');

-- Restaurar original master también como reader (HG 20)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections, max_replication_lag, status) 
VALUES (20, '$ORIGINAL_MASTER', 3306, 100, 100, 5, 'ONLINE');

-- Configurar actual master como reader solo (HG 20)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight, max_connections, max_replication_lag, status) 
VALUES (20, '$CURRENT_MASTER', 3306, 100, 100, 5, 'ONLINE');

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
echo "   2. Replicación: docker exec $CURRENT_MASTER bash -c 'cat > /tmp/.my.cnf << EOF
[client]
user=$MYSQL_REPLICATION_USER
password=$MYSQL_REPLICATION_PASSWORD
EOF
mysql --defaults-extra-file=/tmp/.my.cnf -e \"SHOW REPLICA STATUS\G\"; rm -f /tmp/.my.cnf'"
echo "   3. Logs ProxySQL: docker logs -f $PROXYSQL_CONTAINER"
echo "=========================================="
