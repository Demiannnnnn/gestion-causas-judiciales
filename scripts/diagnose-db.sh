#!/bin/bash

# Script de Diagnóstico para MySQL Master-Slave con ProxySQL
# =============================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    DIAGNÓSTICO: MySQL Master-Slave + ProxySQL                 ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Cargar variables de entorno
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    exit 1
fi

set -a
source .env
set +a

# Verificar que los contenedores estén corriendo
echo -e "${YELLOW}1. Verificando estado de contenedores...${NC}"
echo ""
docker compose ps | grep -E "db-master|db-slave|db-proxy"
echo ""

# Verificar que db-master está healthy
MASTER_STATUS=$(docker compose ps db-master --format json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('Health', 'unknown'))" 2>/dev/null || echo "unknown")
echo -e "Estado de db-master: ${MASTER_STATUS}"

if [ "$MASTER_STATUS" != "healthy" ]; then
    echo -e "${RED}❌ db-master NO está healthy${NC}"
    echo ""
    echo -e "${YELLOW}Logs de db-master:${NC}"
    docker compose logs --tail=50 db-master
else
    echo -e "${GREEN}✅ db-master está healthy${NC}"
fi
echo ""

# Verificar configuración del master
echo -e "${YELLOW}2. Configuración del MASTER...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "
    SHOW VARIABLES LIKE 'server_id';
    SHOW VARIABLES LIKE 'log_bin';
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'enforce_gtid_consistency';
" 2>/dev/null || echo -e "${RED}❌ No se pudo conectar al master${NC}"
echo ""

# Ver el estado del master
echo -e "${YELLOW}3. Estado del MASTER (binlog)...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "
    SHOW BINARY LOG STATUS\G
" 2>/dev/null || echo -e "${RED}❌ No se pudo obtener el estado del master${NC}"
echo ""

# Verificar usuarios de replicación
echo -e "${YELLOW}4. Verificando usuarios de replicación...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "
    SELECT User, Host, plugin FROM mysql.user WHERE User IN ('replicator', 'monitor_user', 'appuser');
" 2>/dev/null || echo -e "${RED}❌ No se pudo verificar usuarios${NC}"
echo ""

# Verificar permisos del usuario replicator
echo -e "${YELLOW}5. Permisos del usuario replicator...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "
    SHOW GRANTS FOR 'replicator'@'%';
" 2>/dev/null || echo -e "${RED}❌ Usuario replicator no existe o no tiene permisos${NC}"
echo ""

# Verificar configuración del slave
echo -e "${YELLOW}6. Configuración del SLAVE...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "
    SHOW VARIABLES LIKE 'server_id';
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'read_only';
" 2>/dev/null || echo -e "${RED}❌ No se pudo conectar al slave${NC}"
echo ""

# Ver el estado de replicación del slave
echo -e "${YELLOW}7. Estado de REPLICACIÓN en el SLAVE...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "
    SHOW REPLICA STATUS\G
" 2>/dev/null || echo -e "${RED}❌ No se pudo obtener el estado de replicación${NC}"
echo ""

# Verificar conectividad entre slave y master
echo -e "${YELLOW}8. Test de conectividad SLAVE → MASTER...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_REPLICATION_PASSWORD}" db-slave mysql -h db-master -ureplicator -e "
    SELECT 'Conexión exitosa' AS Status;
" 2>/dev/null && echo -e "${GREEN}✅ Slave puede conectarse al Master${NC}" || echo -e "${RED}❌ Slave NO puede conectarse al Master${NC}"
echo ""

# Verificar ProxySQL
echo -e "${YELLOW}9. Estado de ProxySQL...${NC}"
echo ""
PROXY_RUNNING=$(docker compose ps db-proxy --format "{{.Status}}" 2>/dev/null | grep -i "up" || echo "down")
if [ "$PROXY_RUNNING" != "down" ]; then
    echo -e "${GREEN}✅ ProxySQL está corriendo${NC}"
    
    # Verificar backends en ProxySQL
    echo ""
    echo -e "${YELLOW}10. Backends configurados en ProxySQL...${NC}"
    echo ""
    docker compose exec -T db-proxy mysql -h 127.0.0.1 -P 6032 -uadmin -padmin -e "
        SELECT * FROM mysql_servers;
    " 2>/dev/null || echo -e "${RED}❌ No se pudo consultar ProxySQL${NC}"
    
    echo ""
    echo -e "${YELLOW}11. Estado de salud de backends (ProxySQL)...${NC}"
    echo ""
    docker compose exec -T db-proxy mysql -h 127.0.0.1 -P 6032 -uadmin -padmin -e "
        SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 10;
    " 2>/dev/null || echo -e "${YELLOW}⚠️  No hay logs de ping disponibles${NC}"
    
    echo ""
    echo -e "${YELLOW}12. Usuarios configurados en ProxySQL...${NC}"
    echo ""
    docker compose exec -T db-proxy mysql -h 127.0.0.1 -P 6032 -uadmin -padmin -e "
        SELECT username, default_hostgroup, active FROM mysql_users;
    " 2>/dev/null || echo -e "${RED}❌ No se pudo consultar usuarios de ProxySQL${NC}"
else
    echo -e "${RED}❌ ProxySQL NO está corriendo${NC}"
fi
echo ""

# Test de conectividad a través de ProxySQL
echo -e "${YELLOW}13. Test de conexión a través de ProxySQL...${NC}"
echo ""
docker compose exec -T -e MYSQL_PWD="${MYSQL_PASSWORD}" db-proxy mysql -h 127.0.0.1 -P 6033 -u"${MYSQL_USER}" -e "
    SELECT 'Conexión exitosa a través de ProxySQL' AS Status;
    SELECT @@hostname AS 'Connected to';
" 2>/dev/null && echo -e "${GREEN}✅ Conexión exitosa a través de ProxySQL${NC}" || echo -e "${RED}❌ No se puede conectar a través de ProxySQL${NC}"
echo ""

# Verificar certificados SSL
echo -e "${YELLOW}14. Verificando certificados SSL...${NC}"
echo ""
if [ -d "db/certs" ]; then
    echo -e "${GREEN}✅ Directorio de certificados existe${NC}"
    ls -lh db/certs/
else
    echo -e "${RED}❌ No se encuentra el directorio de certificados${NC}"
fi
echo ""

# Resumen
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    RESUMEN DEL DIAGNÓSTICO                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Variables de verificación
MASTER_OK=0
SLAVE_OK=0
PROXY_OK=0

docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "SELECT 1" &>/dev/null && MASTER_OK=1
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "SELECT 1" &>/dev/null && SLAVE_OK=1
[ "$PROXY_RUNNING" != "down" ] && PROXY_OK=1

echo "Componente          Estado"
echo "────────────────────────────────────"
[ $MASTER_OK -eq 1 ] && echo -e "db-master           ${GREEN}✅ OK${NC}" || echo -e "db-master           ${RED}❌ ERROR${NC}"
[ $SLAVE_OK -eq 1 ] && echo -e "db-slave            ${GREEN}✅ OK${NC}" || echo -e "db-slave            ${RED}❌ ERROR${NC}"
[ $PROXY_OK -eq 1 ] && echo -e "db-proxy            ${GREEN}✅ OK${NC}" || echo -e "db-proxy            ${RED}❌ ERROR${NC}"
echo ""

# Recomendaciones
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      RECOMENDACIONES                          ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $MASTER_OK -eq 0 ]; then
    echo -e "${RED}❌ MASTER no responde:${NC}"
    echo "   - Verifica logs: docker compose logs db-master"
    echo "   - Verifica healthcheck: docker compose ps db-master"
    echo ""
fi

if [ $SLAVE_OK -eq 0 ]; then
    echo -e "${RED}❌ SLAVE no responde:${NC}"
    echo "   - Verifica logs: docker compose logs db-slave"
    echo "   - Verifica que el script de init se ejecutó correctamente"
    echo ""
fi

if [ $PROXY_OK -eq 0 ]; then
    echo -e "${RED}❌ PROXY no responde:${NC}"
    echo "   - Verifica logs: docker compose logs db-proxy"
    echo "   - Verifica configuración de ProxySQL"
    echo ""
fi

echo -e "${YELLOW}Para más detalles, ejecuta:${NC}"
echo "  docker compose logs db-master"
echo "  docker compose logs db-slave"
echo "  docker compose logs db-proxy"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
