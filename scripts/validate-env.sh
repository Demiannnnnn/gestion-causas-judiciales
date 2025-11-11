#!/bin/bash

# Script para validar que todas las variables requeridas están en .env

set -e

echo "============================================"
echo "  Validador de Variables de Entorno"
echo "============================================"
echo ""

# Variables requeridas
REQUIRED_VARS=(
    # MySQL
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_DATABASE"
    "MYSQL_USER"
    "MYSQL_PASSWORD"
    "MYSQL_MONITOR_USER"
    "MYSQL_MONITOR_PASSWORD"
    
    # Redis
    "REDIS_PASSWORD"
    
    # JWT
    "JWT_SECRET_KEY"
    "CASOS_SECRET_KEY"
    
    # ProxySQL
    "PROXYSQL_ADMIN_USER"
    "PROXYSQL_ADMIN_PASSWORD"
    
    # Prometheus
    "PROMETHEUS_SCRAPE_INTERVAL"
    "PROMETHEUS_EVALUATION_INTERVAL"
)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cargar .env si existe
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo -e "${YELLOW}Copia .env.example a .env primero:${NC}"
    echo "  cp .env.example .env"
    exit 1
fi

# Source .env
set -a
source .env
set +a

echo "Verificando variables requeridas..."
echo ""

MISSING=0

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo -e "${RED}❌ Falta: $VAR${NC}"
        MISSING=$((MISSING + 1))
    else
        echo -e "${GREEN}✅ OK: $VAR${NC}"
    fi
done

echo ""
echo "============================================"

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las variables están configuradas${NC}"
    echo ""
    echo "Puedes iniciar el sistema con:"
    echo "  docker compose up -d"
    exit 0
else
    echo -e "${RED}❌ Faltan $MISSING variable(s)${NC}"
    echo ""
    echo "Revisa el archivo .env.example para ver las variables necesarias"
    exit 1
fi
