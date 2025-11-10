#!/bin/bash

# Script mejorado de diagnóstico - Sin warnings de password
# =========================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    DIAGNÓSTICO RÁPIDO: MySQL Master-Slave                     ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Cargar variables
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

set -a
source .env
set +a

# Función helper para ejecutar comandos MySQL sin warnings
mysql_exec() {
    local container=$1
    local user=$2
    local password=$3
    shift 3
    docker compose exec -T -e MYSQL_PWD="$password" "$container" mysql -u"$user" "$@" 2>&1 | grep -v "Using a password on the command line"
}

# 1. Estado de contenedores
echo -e "${YELLOW}1. Estado de contenedores...${NC}"
docker compose ps db-master db-slave db-proxy 2>/dev/null | grep -E "NAME|db-master|db-slave|db-proxy" || echo -e "${RED}❌ Contenedores no están corriendo${NC}"
echo ""

# 2. Test de conectividad básica
echo -e "${YELLOW}2. Conectividad básica...${NC}"
if mysql_exec db-master root "${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Master OK' AS status" &>/dev/null; then
    echo -e "  Master:  ${GREEN}✅ OK${NC}"
else
    echo -e "  Master:  ${RED}❌ ERROR${NC}"
fi

if mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" -e "SELECT 'Slave OK' AS status" &>/dev/null; then
    echo -e "  Slave:   ${GREEN}✅ OK${NC}"
else
    echo -e "  Slave:   ${RED}❌ ERROR${NC}"
fi
echo ""

# 3. Verificar GTID
echo -e "${YELLOW}3. Configuración GTID...${NC}"
echo "  Master:"
mysql_exec db-master root "${MYSQL_ROOT_PASSWORD}" -e "
    SELECT 
        @@server_id AS server_id,
        @@gtid_mode AS gtid_mode,
        @@log_bin AS log_bin
" 2>/dev/null | grep -v "Using a password"

echo "  Slave:"
mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" -e "
    SELECT 
        @@server_id AS server_id,
        @@gtid_mode AS gtid_mode,
        @@read_only AS read_only
" 2>/dev/null | grep -v "Using a password"
echo ""

# 4. Estado de replicación
echo -e "${YELLOW}4. Estado de replicación...${NC}"
REPL_STATUS=$(mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" -e "SHOW REPLICA STATUS\G" 2>/dev/null)

IO_RUNNING=$(echo "$REPL_STATUS" | grep "Replica_IO_Running:" | awk '{print $2}')
SQL_RUNNING=$(echo "$REPL_STATUS" | grep "Replica_SQL_Running:" | awk '{print $2}')
SECONDS_BEHIND=$(echo "$REPL_STATUS" | grep "Seconds_Behind_Source:" | awk '{print $2}')
LAST_ERROR=$(echo "$REPL_STATUS" | grep "Last_Error:" | cut -d: -f2-)

echo "  IO Thread:  $IO_RUNNING"
echo "  SQL Thread: $SQL_RUNNING"
echo "  Lag:        $SECONDS_BEHIND seconds"

if [ ! -z "$LAST_ERROR" ] && [ "$LAST_ERROR" != " " ]; then
    echo -e "  ${RED}Error: $LAST_ERROR${NC}"
fi
echo ""

# 5. Usuario replicator
echo -e "${YELLOW}5. Usuario replicator...${NC}"
if mysql_exec db-master root "${MYSQL_ROOT_PASSWORD}" -e "SELECT User FROM mysql.user WHERE User='replicator'" 2>/dev/null | grep -q replicator; then
    echo -e "  ${GREEN}✅ Usuario existe${NC}"
else
    echo -e "  ${RED}❌ Usuario NO existe${NC}"
fi
echo ""

# 6. Test de conectividad slave → master
echo -e "${YELLOW}6. Conectividad slave → master...${NC}"
if docker compose exec -T -e MYSQL_PWD="${MYSQL_REPLICATION_PASSWORD}" db-slave mysql -h db-master -ureplicator --ssl-mode=REQUIRED -e "SELECT 1" &>/dev/null; then
    echo -e "  ${GREEN}✅ Slave puede conectarse al master${NC}"
else
    echo -e "  ${RED}❌ Slave NO puede conectarse al master${NC}"
fi
echo ""

# 7. ProxySQL
echo -e "${YELLOW}7. ProxySQL...${NC}"
if docker compose ps db-proxy 2>/dev/null | grep -q "Up"; then
    echo -e "  Estado: ${GREEN}✅ Corriendo${NC}"
    
    # Verificar backends
    BACKENDS=$(docker compose exec -T db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "SELECT hostname, port, status FROM mysql_servers;" 2>/dev/null | grep -v "Using a password")
    if [ ! -z "$BACKENDS" ]; then
        echo "  Backends:"
        echo "$BACKENDS"
    fi
else
    echo -e "  ${RED}❌ ProxySQL no está corriendo${NC}"
fi
echo ""

# 8. Certificados SSL
echo -e "${YELLOW}8. Certificados SSL...${NC}"
if [ -d "db/certs" ]; then
    CERT_COUNT=$(ls db/certs/*.pem 2>/dev/null | wc -l)
    if [ $CERT_COUNT -gt 0 ]; then
        echo -e "  ${GREEN}✅ Encontrados $CERT_COUNT certificados${NC}"
    else
        echo -e "  ${RED}❌ No se encontraron certificados${NC}"
    fi
else
    echo -e "  ${RED}❌ Directorio de certificados no existe${NC}"
fi
echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                         RESUMEN                                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
    echo -e "${GREEN}✅ REPLICACIÓN FUNCIONANDO CORRECTAMENTE${NC}"
elif [ "$IO_RUNNING" = "Connecting" ]; then
    echo -e "${YELLOW}⚠️  REPLICACIÓN INTENTANDO CONECTAR${NC}"
    echo "   Ejecuta: ./scripts/fix-replication.sh"
elif [ "$IO_RUNNING" = "No" ] || [ "$SQL_RUNNING" = "No" ]; then
    echo -e "${RED}❌ REPLICACIÓN CON PROBLEMAS${NC}"
    echo "   Ejecuta: ./scripts/fix-replication.sh"
else
    echo -e "${YELLOW}⚠️  REPLICACIÓN NO CONFIGURADA${NC}"
    echo "   Ejecuta: ./scripts/fix-replication.sh"
fi

echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "  Diagnóstico completo: ./scripts/diagnose-db.sh"
echo "  Reparar replicación:  ./scripts/fix-replication.sh"
echo "  Ver logs:             docker compose logs db-master db-slave"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
