#!/bin/bash
# Script para actualizar permisos en contenedores sin reiniciar
# Esto es temporal hasta la próxima reinicialización con docker-compose

set -e

# Cargar variables de entorno
if [ -f "$(dirname "$0")/../.env" ]; then
    set -a
    source "$(dirname "$0")/../.env"
    set +a
fi

MYSQL_REPLICATION_USER="${MYSQL_REPLICATION_USER:-replicator}"
MYSQL_REPLICATION_PASSWORD="${MYSQL_REPLICATION_PASSWORD:-***REMOVED***}"
MYSQL_MONITOR_USER="${MYSQL_MONITOR_USER:-monitor_user}"
MYSQL_MONITOR_PASSWORD="${MYSQL_MONITOR_PASSWORD:-***REMOVED***}"

echo "=========================================="
echo "Actualizando permisos en contenedores"
echo "=========================================="
echo ""

# Verificar si db-slave está corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^db-slave$"; then
    echo "❌ db-slave no está corriendo"
    exit 1
fi

echo "1. Otorgando SUPER a replicator en db-slave..."
cat << SQL | sudo docker exec -i db-slave mysql -u"$MYSQL_REPLICATION_USER" -p"$MYSQL_REPLICATION_PASSWORD" 2>&1
GRANT SUPER ON *.* TO '$MYSQL_REPLICATION_USER'@'%';
FLUSH PRIVILEGES;
SQL

echo "✅ Permisos actualizados"
echo ""

echo "2. Verificando permisos del replicator..."
sudo docker exec -e MYSQL_PWD="$MYSQL_REPLICATION_PASSWORD" db-slave \
    mysql -u"$MYSQL_REPLICATION_USER" -NB -e "SHOW GRANTS FOR '$MYSQL_REPLICATION_USER'@'%';" 2>&1

echo ""
echo "3. Verificando permisos del monitor..."
sudo docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" db-slave \
    mysql -u"$MYSQL_MONITOR_USER" -NB -e "SHOW GRANTS FOR '$MYSQL_MONITOR_USER'@'%';" 2>&1

echo ""
echo "=========================================="
echo "✅ Permisos actualizados exitosamente"
echo "=========================================="
echo ""
echo "⚠️  NOTA: Estos cambios son TEMPORALES hasta que reinicialices"
echo "   los contenedores. Para hacerlos PERSISTENTES:"
echo ""
echo "   1. Reinicia docker-compose:"
echo "      sudo docker-compose down"
echo "      sudo docker-compose up"
echo ""
echo "   2. O espera al próximo deployment que usará la BD"
echo "      con los permisos correctos en init.sql"
echo ""
