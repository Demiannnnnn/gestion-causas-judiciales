#!/bin/bash
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Sistema de Gestión de Causas Judiciales    ${NC}"
echo -e "${BLUE}     Inicio Asistido de Infraestructura       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker y Docker Compose encontrados${NC}"
echo ""

# Paso 1: Verificar .env
echo -e "${YELLOW}Paso 1: Verificando archivo .env...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado. Copiando desde .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ Archivo .env creado${NC}"
    echo -e "${YELLOW}⚠️  Por favor, revisa y ajusta las variables en .env${NC}"
    echo ""
    read -p "Presiona Enter para continuar o Ctrl+C para salir y editar .env..."
fi

# Validar variables
echo -e "${YELLOW}Validando variables requeridas...${NC}"
./scripts/validate-env.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Faltan variables requeridas en .env${NC}"
    exit 1
fi
echo ""

# Paso 2: Limpiar contenedores anteriores (opcional)
echo -e "${YELLOW}Paso 2: ¿Deseas limpiar contenedores y volúmenes anteriores?${NC}"
read -p "Esto eliminará datos existentes (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Limpiando sistema anterior...${NC}"
    docker compose down -v 2>/dev/null || true
    echo -e "${GREEN}✅ Sistema limpio${NC}"
fi
echo ""

# Paso 3: Verificar certificados TLS
echo -e "${YELLOW}Paso 3: Verificando certificados TLS...${NC}"
if [ ! -f db/certs/server-cert.pem ] || [ ! -f api-gateway/certs-local/cert.pem ]; then
    echo -e "${YELLOW}Generando certificados TLS autofirmados...${NC}"
    ./db/generate-certs.sh
fi
echo -e "${GREEN}✅ Certificados TLS listos${NC}"
echo ""

# Paso 4: Iniciar servicios de base de datos
echo -e "${YELLOW}Paso 4: Iniciando base de datos...${NC}"
docker compose up -d db-init db-master
echo -e "${YELLOW}Esperando a que la base de datos esté lista...${NC}"
sleep 10
echo -e "${GREEN}✅ Base de datos iniciada${NC}"
echo ""

# Paso 5: Iniciar todos los servicios
echo -e "${YELLOW}Paso 5: Iniciando todos los servicios...${NC}"
docker compose up -d
echo ""

# Esperar a que los servicios estén listos
echo -e "${YELLOW}Esperando a que los servicios inicien...${NC}"
sleep 5
echo ""

# Paso 6: Verificar estado
echo -e "${YELLOW}Paso 6: Verificando estado de servicios...${NC}"
echo ""
docker compose ps
echo ""

# Resumen
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}     ✅ Sistema iniciado exitosamente ✅       ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Servicios disponibles:${NC}"
echo ""
echo -e "  🌐 Frontend:          ${GREEN}http://localhost:8081${NC}"
echo -e "  🚪 API Gateway:       ${GREEN}http://localhost:8081/api${NC}"
echo -e "  📊 Traefik Dashboard: ${GREEN}http://localhost:8080${NC}"
echo -e "  📈 Prometheus:        ${GREEN}http://localhost:9090${NC}"
echo -e "  📉 Grafana:           ${GREEN}http://localhost:3000${NC}"
echo -e "     Usuario: admin / Contraseña: admin"
echo -e "  📧 MailHog:           ${GREEN}http://localhost:8025${NC}"
echo -e "  🗄️  MySQL Master:      ${GREEN}localhost:3307${NC}"
echo -e "  🗄️  MySQL Slave:       ${GREEN}localhost:3308${NC}"
echo -e "  🔴 Redis:             ${GREEN}localhost:6379${NC}"
echo -e "  🟢 Redis Replica:     ${GREEN}localhost:6380${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo ""
echo -e "  Ver logs:             ${YELLOW}docker compose logs -f [servicio]${NC}"
echo -e "  Detener sistema:      ${YELLOW}docker compose down${NC}"
echo -e "  Reiniciar servicio:   ${YELLOW}docker compose restart [servicio]${NC}"
echo -e "  Ver estado:           ${YELLOW}docker compose ps${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
