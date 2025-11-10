#!/bin/bash

# Script para reiniciar y reparar la replicación MySQL Master-Slave
# ==================================================================
# Versión mejorada con mejor manejo de errores

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

# Función para ejecutar comandos MySQL
mysql_exec() {
    local container=$1
    local user=$2
    local password=$3
    shift 3
    docker compose exec -T -e MYSQL_PWD="$password" "$container" mysql -u"$user" "$@" 2>&1
}

# Verificar que los contenedores estén corriendo
echo -e "${YELLOW}Verificando contenedores...${NC}"
if ! docker compose ps db-master 2>/dev/null | grep -q "Up"; then
    echo -e "${RED}❌ db-master no está corriendo${NC}"
    echo "   Inicia con: docker compose up -d db-master"
    exit 1
fi

if ! docker compose ps db-slave 2>/dev/null | grep -q "Up"; then
    echo -e "${RED}❌ db-slave no está corriendo${NC}"
    echo "   Inicia con: docker compose up -d db-slave"
    exit 1
fi
echo -e "${GREEN}✅ Contenedores corriendo${NC}"
echo ""

# Paso 1: Detener replicación en el slave
echo -e "${YELLOW}Paso 1: Deteniendo replicación en el slave...${NC}"
if mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    STOP REPLICA;
    RESET REPLICA ALL;
EOSQL
then
    echo -e "${GREEN}✅ Replicación detenida${NC}"
else
    echo -e "${YELLOW}⚠️  La replicación ya estaba detenida o no estaba configurada${NC}"
fi
echo ""

# Paso 2: Verificar estado del master
echo -e "${YELLOW}Paso 2: Verificando estado del master...${NC}"
MASTER_STATUS=$(mysql_exec db-master root "${MYSQL_ROOT_PASSWORD}" -e "SHOW BINARY LOG STATUS\G" 2>&1)

if [ $? -eq 0 ]; then
    echo "$MASTER_STATUS"
    echo -e "${GREEN}✅ Master respondiendo correctamente${NC}"
else
    echo -e "${RED}❌ No se pudo conectar al master${NC}"
    echo "   Verifica: docker compose logs db-master"
    exit 1
fi
echo ""

# Verificar que el master tiene binlog habilitado
if echo "$MASTER_STATUS" | grep -q "File:"; then
    echo -e "${GREEN}✅ Binary logging habilitado${NC}"
else
    echo -e "${RED}❌ Binary logging NO está habilitado en el master${NC}"
    echo "   El master debe tener --log-bin configurado"
    exit 1
fi
echo ""

# Paso 3: Verificar/crear usuario replicator
echo -e "${YELLOW}Paso 3: Configurando usuario replicator...${NC}"

REPLICATOR_OUTPUT=$(mysql_exec db-master root "${MYSQL_ROOT_PASSWORD}" <<-EOSQL 2>&1
	DROP USER IF EXISTS 'replicator'@'%';
	CREATE USER 'replicator'@'%' 
	    IDENTIFIED WITH caching_sha2_password 
	    BY '${MYSQL_REPLICATION_PASSWORD}' 
	    REQUIRE SSL;
	GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'%';
	FLUSH PRIVILEGES;
	SELECT User, Host FROM mysql.user WHERE User='replicator';
EOSQL
)
REPLICATOR_EXIT=$?

if [ $REPLICATOR_EXIT -eq 0 ] && echo "$REPLICATOR_OUTPUT" | grep -q "replicator"; then
    echo -e "${GREEN}✅ Usuario replicator configurado${NC}"
    echo "$REPLICATOR_OUTPUT" | tail -3
else
    echo -e "${RED}❌ Error al crear usuario replicator${NC}"
    echo ""
    echo "Salida completa:"
    echo "$REPLICATOR_OUTPUT"
    echo ""
    exit 1
fi
echo ""

# Paso 4: Test de conectividad slave → master
echo -e "${YELLOW}Paso 4: Test de conectividad slave → master...${NC}"

# Probar conectividad MySQL directamente (esto valida red + puerto + servicio)
echo "  Probando autenticación MySQL con SSL..."
if docker compose exec -T -e MYSQL_PWD="${MYSQL_REPLICATION_PASSWORD}" db-slave mysql -ureplicator -hdb-master --ssl-mode=REQUIRED -e "SELECT 'OK' AS connection_test" 2>&1 | grep -q "OK"; then
    echo -e "  ${GREEN}✅ Conectividad MySQL con SSL: OK${NC}"
    USE_SSL=1
else
    echo -e "  ${YELLOW}⚠️  Error con SSL, probando sin SSL...${NC}"
    if docker compose exec -T -e MYSQL_PWD="${MYSQL_REPLICATION_PASSWORD}" db-slave mysql -ureplicator -hdb-master -e "SELECT 'OK' AS connection_test" 2>&1 | grep -q "OK"; then
        echo -e "  ${YELLOW}⚠️  Conectividad sin SSL: OK${NC}"
        echo -e "  ${YELLOW}⚠️  ADVERTENCIA: Los certificados SSL pueden tener problemas${NC}"
        USE_SSL=0
    else
        echo -e "  ${RED}❌ No se puede conectar al master${NC}"
        echo ""
        echo "  Verifica:"
        echo "    1. Password de replicación: echo \$MYSQL_REPLICATION_PASSWORD"
        echo "    2. Usuario existe: docker compose exec db-master mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" -e \"SELECT User FROM mysql.user WHERE User='replicator'\""
        echo "    3. Certificados: docker compose exec db-slave ls -la /etc/mysql/certs/"
        echo ""
        echo "  Depuración adicional:"
        echo "    docker compose exec db-master mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" -e \"SELECT User, Host FROM mysql.user WHERE User='replicator'\""
        exit 1
    fi
fi
echo ""

# Paso 5: Configurar replicación en el slave
echo -e "${YELLOW}Paso 5: Configurando replicación en el slave...${NC}"

# Determinar si usar SSL o no
if [ "${USE_SSL:-1}" -eq 1 ]; then
    REPL_CONFIG="
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
    "
    echo "  Configurando con SSL..."
else
    REPL_CONFIG="
    CHANGE REPLICATION SOURCE TO
        SOURCE_HOST='db-master',
        SOURCE_USER='replicator',
        SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        SOURCE_AUTO_POSITION=1,
        GET_SOURCE_PUBLIC_KEY=1;
    "
    echo "  Configurando sin SSL..."
fi

REPL_OUTPUT=$(mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" <<EOSQL 2>&1
    $REPL_CONFIG
    START REPLICA;
EOSQL
)
REPL_EXIT=$?

if [ $REPL_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ Replicación configurada e iniciada${NC}"
else
    echo -e "${RED}❌ Error al configurar la replicación${NC}"
    echo ""
    echo "Salida del error:"
    echo "$REPL_OUTPUT"
    echo ""
    exit 1
fi
echo ""

# Paso 6: Esperar y verificar
echo -e "${YELLOW}Esperando 5 segundos para que la replicación se estabilice...${NC}"
sleep 5
echo ""

echo -e "${YELLOW}Paso 6: Verificando estado de la replicación...${NC}"
REPL_STATUS=$(mysql_exec db-slave root "${MYSQL_ROOT_PASSWORD}" -e "SHOW REPLICA STATUS\G" 2>&1)

# Extraer valores importantes
IO_RUNNING=$(echo "$REPL_STATUS" | grep "Replica_IO_Running:" | head -1 | awk '{print $2}')
SQL_RUNNING=$(echo "$REPL_STATUS" | grep "Replica_SQL_Running:" | head -1 | awk '{print $2}')
SECONDS_BEHIND=$(echo "$REPL_STATUS" | grep "Seconds_Behind_Source:" | head -1 | awk '{print $2}')
LAST_IO_ERROR=$(echo "$REPL_STATUS" | grep "Last_IO_Error:" | cut -d: -f2-)
LAST_SQL_ERROR=$(echo "$REPL_STATUS" | grep "Last_SQL_Error:" | cut -d: -f2-)

echo ""
echo "Estado actual:"
echo "  Replica_IO_Running:  ${IO_RUNNING}"
echo "  Replica_SQL_Running: ${SQL_RUNNING}"
echo "  Seconds_Behind:      ${SECONDS_BEHIND}"

if [ ! -z "$LAST_IO_ERROR" ] && [ "$LAST_IO_ERROR" != " " ]; then
    echo -e "  ${RED}Last_IO_Error: ${LAST_IO_ERROR}${NC}"
fi

if [ ! -z "$LAST_SQL_ERROR" ] && [ "$LAST_SQL_ERROR" != " " ]; then
    echo -e "  ${RED}Last_SQL_Error: ${LAST_SQL_ERROR}${NC}"
fi
echo ""

# Resultado final
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    RESULTADO                                  ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
    echo -e "${GREEN}✅ ¡REPLICACIÓN FUNCIONANDO CORRECTAMENTE!${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "  • Monitorear: docker compose exec db-slave mysql -uroot -e 'SHOW REPLICA STATUS\\G' | grep Running"
    echo "  • Test: Inserta datos en el master y verifica que aparezcan en el slave"
    
elif [ "$IO_RUNNING" = "Connecting" ]; then
    echo -e "${YELLOW}⚠️  REPLICACIÓN INTENTANDO CONECTAR${NC}"
    echo ""
    echo "El slave está intentando conectarse al master."
    echo "Esto puede tomar unos segundos. Monitorea con:"
    echo "  watch -n 2 'docker compose exec -T db-slave mysql -uroot -e \"SHOW REPLICA STATUS\\G\" | grep -E \"Running|Error\"'"
    
elif [ "$IO_RUNNING" = "No" ] || [ "$SQL_RUNNING" = "No" ]; then
    echo -e "${RED}❌ LA REPLICACIÓN TIENE PROBLEMAS${NC}"
    echo ""
    echo "Replica_IO_Running:  $IO_RUNNING"
    echo "Replica_SQL_Running: $SQL_RUNNING"
    echo ""
    echo "Verifica los errores completos:"
    echo "  docker compose exec db-slave mysql -uroot -e 'SHOW REPLICA STATUS\\G'"
    echo ""
    echo "Problemas comunes:"
    echo "  • Certificados SSL: Verifica db/certs/"
    echo "  • Usuario replicator: Verifica grants en el master"
    echo "  • Conectividad: docker compose exec db-slave ping db-master"
    
else
    echo -e "${YELLOW}⚠️  ESTADO DESCONOCIDO${NC}"
    echo ""
    echo "Verifica manualmente:"
    echo "  docker compose exec db-slave mysql -uroot -e 'SHOW REPLICA STATUS\\G'"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
