#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Config Initialization Management Script ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  init-all       - Inicializa todas las configuraciones"
    echo "  init-prometheus - Inicializa solo configuración de Prometheus"
    echo "  init-redis     - Inicializa solo configuración de Redis"
    echo "  init-proxysql  - Inicializa solo configuración de ProxySQL"
    echo "  init-traefik   - Inicializa solo configuración de Traefik"
    echo "  clean          - Limpia todos los volúmenes de configuración"
    echo "  status         - Muestra el estado de los contenedores de inicialización"
    echo "  logs [service] - Muestra logs del contenedor de inicialización"
    echo "  help           - Muestra esta ayuda"
    echo ""
}

# Función para inicializar todas las configs
init_all() {
    echo -e "${YELLOW}Inicializando todas las configuraciones...${NC}"
    docker compose up -d config-init-prometheus config-init-redis config-init-proxysql config-init-traefik
    docker compose logs config-init-prometheus config-init-redis config-init-proxysql config-init-traefik
    echo -e "${GREEN}✅ Inicialización completada${NC}"
}

# Función para inicializar servicio específico
init_service() {
    SERVICE=$1
    echo -e "${YELLOW}Inicializando configuración de $SERVICE...${NC}"
    docker compose up -d config-init-$SERVICE
    docker compose logs config-init-$SERVICE
    echo -e "${GREEN}✅ Configuración de $SERVICE inicializada${NC}"
}

# Función para limpiar volúmenes
clean() {
    echo -e "${RED}⚠️  ADVERTENCIA: Esto eliminará todos los volúmenes de configuración${NC}"
    read -p "¿Está seguro? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deteniendo servicios...${NC}"
        docker compose down
        echo -e "${YELLOW}Eliminando volúmenes de configuración...${NC}"
        docker volume rm proy2_prometheus-config proy2_redis-config proy2_proxysql-config proy2_traefik-config 2>/dev/null || true
        echo -e "${GREEN}✅ Volúmenes eliminados${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

# Función para mostrar estado
status() {
    echo -e "${YELLOW}Estado de contenedores de inicialización:${NC}"
    echo ""
    docker compose ps config-init-prometheus config-init-redis config-init-proxysql config-init-traefik
}

# Función para mostrar logs
show_logs() {
    SERVICE=$1
    if [ -z "$SERVICE" ]; then
        echo -e "${YELLOW}Mostrando logs de todos los contenedores de inicialización:${NC}"
        docker compose logs config-init-prometheus config-init-redis config-init-proxysql config-init-traefik
    else
        echo -e "${YELLOW}Mostrando logs de config-init-$SERVICE:${NC}"
        docker compose logs config-init-$SERVICE
    fi
}

# Procesamiento de comandos
case "${1:-help}" in
    init-all)
        init_all
        ;;
    init-prometheus)
        init_service "prometheus"
        ;;
    init-redis)
        init_service "redis"
        ;;
    init-proxysql)
        init_service "proxysql"
        ;;
    init-traefik)
        init_service "traefik"
        ;;
    clean)
        clean
        ;;
    status)
        status
        ;;
    logs)
        show_logs "${2}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Comando desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}============================================${NC}"
