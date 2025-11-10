#!/bin/bash

# Script para reiniciar y reparar la replicación MySQL Master-Slave
# ==================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    REPARACIÓN: MySQL Master-Slave Replication                 ${NC}"
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

echo -e "${YELLOW}Paso 1: Deteniendo replicación en el slave...${NC}"
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot <<-EOSQL
    STOP REPLICA;
    RESET REPLICA ALL;
EOSQL
echo -e "${GREEN}✅ Replicación detenida${NC}"
echo ""

echo -e "${YELLOW}Paso 2: Verificando estado del master...${NC}"
MASTER_STATUS=$(docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot -e "SHOW MASTER STATUS\G" 2>/dev/null)
echo "$MASTER_STATUS"
echo ""

echo -e "${YELLOW}Paso 3: Verificando usuario replicator...${NC}"
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-master mysql -uroot <<-EOSQL
    -- Recrear usuario replicator si es necesario
    DROP USER IF EXISTS 'replicator'@'%';
    CREATE USER 'replicator'@'%' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_REPLICATION_PASSWORD}' REQUIRE SSL;
    GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'%';
    FLUSH PRIVILEGES;
EOSQL
echo -e "${GREEN}✅ Usuario replicator configurado${NC}"
echo ""

echo -e "${YELLOW}Paso 4: Test de conectividad slave → master...${NC}"
if docker compose exec -T -e MYSQL_PWD="${MYSQL_REPLICATION_PASSWORD}" db-slave mysql -h db-master -ureplicator --ssl-mode=REQUIRED -e "SELECT 'OK' AS connection_test;" 2>/dev/null; then
    echo -e "${GREEN}✅ Conectividad OK${NC}"
else
    echo -e "${RED}❌ No hay conectividad. Verifica:${NC}"
    echo "   1. Red: docker compose exec db-slave ping -c 3 db-master"
    echo "   2. Puerto: docker compose exec db-slave nc -zv db-master 3306"
    echo "   3. Certificados SSL en /etc/mysql/certs/"
    exit 1
fi
echo ""

echo -e "${YELLOW}Paso 5: Configurando replicación en el slave...${NC}"
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot <<-EOSQL
    CHANGE REPLICATION SOURCE TO
        SOURCE_HOST='db-master',
        SOURCE_USER='replicator',
        SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        SOURCE_SSL=1,
        SOURCE_SSL_CA='/etc/mysql/certs/ca.pem',
        SOURCE_SSL_CERT='/etc/mysql/certs/client-cert.pem',
        SOURCE_SSL_KEY='/etc/mysql/certs/client-key.pem',
        SOURCE_AUTO_POSITION=1,
        GET_SOURCE_PUBLIC_KEY=1;
    
    START REPLICA;
EOSQL
echo -e "${GREEN}✅ Replicación iniciada${NC}"
echo ""

echo -e "${YELLOW}Esperando 5 segundos para que la replicación se estabilice...${NC}"
sleep 5
echo ""

echo -e "${YELLOW}Paso 6: Verificando estado de la replicación...${NC}"
docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "SHOW REPLICA STATUS\G" | grep -E "Replica_IO_Running|Replica_SQL_Running|Last_Error|Seconds_Behind_Source"
echo ""

# Verificación final
IO_RUNNING=$(docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "SHOW REPLICA STATUS\G" 2>/dev/null | grep "Replica_IO_Running" | awk '{print $2}')
SQL_RUNNING=$(docker compose exec -T -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" db-slave mysql -uroot -e "SHOW REPLICA STATUS\G" 2>/dev/null | grep "Replica_SQL_Running" | awk '{print $2}')

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    RESULTADO                                  ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
    echo -e "${GREEN}✅ ¡REPLICACIÓN FUNCIONANDO CORRECTAMENTE!${NC}"
    echo ""
    echo "Replica_IO_Running:  $IO_RUNNING"
    echo "Replica_SQL_Running: $SQL_RUNNING"
else
    echo -e "${RED}❌ LA REPLICACIÓN TIENE PROBLEMAS${NC}"
    echo ""
    echo "Replica_IO_Running:  $IO_RUNNING"
    echo "Replica_SQL_Running: $SQL_RUNNING"
    echo ""
    echo -e "${YELLOW}Verifica los errores con:${NC}"
    echo "  docker compose exec db-slave mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" -e \"SHOW REPLICA STATUS\\G\""
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
