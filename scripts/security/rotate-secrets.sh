#!/bin/sh

# Script de Rotación de Secretos
# Genera nuevos secretos y actualiza el archivo .env

set -e

# Colores para output
RED='\033[0.31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${YELLOW}========================================${NC}"
echo "${YELLOW}  Rotación de Secretos${NC}"
echo "${YELLOW}========================================${NC}"
echo ""

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo "${RED}Error: No se encontró el archivo .env${NC}"
    exit 1
fi

# Crear backup del .env actual
BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
echo "${YELLOW}→ Creando backup: ${BACKUP_FILE}${NC}"
cp .env "$BACKUP_FILE"

# Función para generar secreto aleatorio
generate_secret() {
    openssl rand -hex 32
}

# Función para actualizar secreto en .env
update_secret() {
    KEY=$1
    NEW_VALUE=$2
    
    if grep -q "^${KEY}=" .env; then
        # Usar sed con delimitador diferente para evitar problemas con /
        sed -i "s|^${KEY}=.*|${KEY}=${NEW_VALUE}|" .env
        echo "${GREEN}✓ ${KEY} actualizado${NC}"
    else
        echo "${RED}✗ ${KEY} no encontrado en .env${NC}"
    fi
}

# Preguntar al usuario qué secretos rotar
echo ""
echo "¿Qué secretos desea rotar?"
echo "1) JWT_SECRET_KEY"
echo "2) CASOS_SECRET_KEY"
echo "3) REDIS_PASSWORD"
echo "4) MYSQL_ROOT_PASSWORD"
echo "5) MYSQL_PASSWORD"
echo "6) Todos los anteriores"
echo "7) Cancelar"
echo ""
read -p "Seleccione una opción (1-7): " option

case $option in
    1)
        NEW_JWT=$(generate_secret)
        update_secret "JWT_SECRET_KEY" "$NEW_JWT"
        ;;
    2)
        NEW_CASOS=$(generate_secret)
        update_secret "CASOS_SECRET_KEY" "$NEW_CASOS"
        ;;
    3)
        NEW_REDIS=$(generate_secret)
        update_secret "REDIS_PASSWORD" "$NEW_REDIS"
        ;;
    4)
        NEW_MYSQL_ROOT=$(generate_secret)
        update_secret "MYSQL_ROOT_PASSWORD" "$NEW_MYSQL_ROOT"
        ;;
    5)
        NEW_MYSQL=$(generate_secret)
        update_secret "MYSQL_PASSWORD" "$NEW_MYSQL"
        ;;
    6)
        echo ""
        echo "${YELLOW}Rotando todos los secretos...${NC}"
        NEW_JWT=$(generate_secret)
        NEW_CASOS=$(generate_secret)
        NEW_REDIS=$(generate_secret)
        NEW_MYSQL_ROOT=$(generate_secret)
        NEW_MYSQL=$(generate_secret)
        
        update_secret "JWT_SECRET_KEY" "$NEW_JWT"
        update_secret "CASOS_SECRET_KEY" "$NEW_CASOS"
        update_secret "REDIS_PASSWORD" "$NEW_REDIS"
        update_secret "MYSQL_ROOT_PASSWORD" "$NEW_MYSQL_ROOT"
        update_secret "MYSQL_PASSWORD" "$NEW_MYSQL"
        ;;
    7)
        echo "${YELLOW}Operación cancelada${NC}"
        rm "$BACKUP_FILE"
        exit 0
        ;;
    *)
        echo "${RED}Opción inválida${NC}"
        rm "$BACKUP_FILE"
        exit 1
        ;;
esac

echo ""
echo "${GREEN}========================================${NC}"
echo "${GREEN}  Rotación completada exitosamente${NC}"
echo "${GREEN}========================================${NC}"
echo ""
echo "${YELLOW}IMPORTANTE:${NC}"
echo "1. Se creó un backup en: ${BACKUP_FILE}"
echo "2. ${RED}Debe reiniciar los contenedores para aplicar los cambios:${NC}"
echo "   ${YELLOW}docker-compose down && docker-compose up -d${NC}"
echo "3. ${RED}Los usuarios existentes con contraseñas antiguas deberán actualizarse${NC}"
echo ""
echo "${YELLOW}¿Desea reiniciar los contenedores ahora? (s/n)${NC}"
read -p "> " restart

if [ "$restart" = "s" ] || [ "$restart" = "S" ]; then
    echo "${YELLOW}Reiniciando contenedores...${NC}"
    docker-compose down
    docker-compose up -d
    echo "${GREEN}✓ Contenedores reiniciados${NC}"
else
    echo "${YELLOW}Recuerde reiniciar manualmente los contenedores${NC}"
fi

echo ""
echo "${GREEN}Proceso completado${NC}"
